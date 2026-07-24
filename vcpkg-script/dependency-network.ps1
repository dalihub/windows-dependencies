$DaliNetworkRetryCount = 10
$DaliNetworkTimeoutSeconds = 10
$DaliNetworkLowSpeedBytesPerSecond = 1024

function ConvertTo-DaliCommandLineArgument
{
  param([string]$Argument)

  if($Argument -notmatch '[\s"]')
  {
    return $Argument
  }

  return '"' + ($Argument -replace '(\\*)"', '$1$1\"' -replace '(\\+)$', '$1$1') + '"'
}

function Set-DaliProxyEnvironment
{
  param([string]$Proxy = "")

  $EffectiveProxy = $Proxy
  if(-not $EffectiveProxy)
  {
    $EffectiveProxy = $env:HTTPS_PROXY
  }
  if(-not $EffectiveProxy)
  {
    $EffectiveProxy = $env:HTTP_PROXY
  }
  if(-not $EffectiveProxy)
  {
    return
  }

  $ProxyAddress = $EffectiveProxy -replace '^[a-zA-Z][a-zA-Z0-9+.-]*://', ''
  $env:VCPKG_PROXY = $ProxyAddress

  if($Proxy)
  {
    $ProxyUri = $Proxy
    if($ProxyUri -notmatch '^[a-zA-Z][a-zA-Z0-9+.-]*://')
    {
      $ProxyUri = "http://$ProxyUri"
    }
    $env:HTTP_PROXY = $ProxyUri
    $env:HTTPS_PROXY = $ProxyUri
  }
}

function Invoke-DaliGit
{
  param(
    [Parameter(Mandatory = $true)]
    [string[]]$Arguments,
    [switch]$AllowFailure,
    [int]$MaxAttempts = 1,
    [int]$TimeoutSeconds = 0,
    [string]$CleanupPathOnRetry = ""
  )

  if($MaxAttempts -lt 1)
  {
    throw "MaxAttempts must be at least 1"
  }

  for($Attempt = 1; $Attempt -le $MaxAttempts; ++$Attempt)
  {
    if($Attempt -gt 1 -and $CleanupPathOnRetry -and (Test-Path -LiteralPath $CleanupPathOnRetry))
    {
      Remove-Item -LiteralPath $CleanupPathOnRetry -Recurse -Force
    }

    $StartInfo = [Diagnostics.ProcessStartInfo]::new()
    $StartInfo.FileName = "git"
    $StartInfo.Arguments = (($Arguments | ForEach-Object { ConvertTo-DaliCommandLineArgument $_ }) -join " ")
    $StartInfo.UseShellExecute = $false
    $StartInfo.RedirectStandardOutput = $true
    $StartInfo.RedirectStandardError = $true
    $StartInfo.CreateNoWindow = $true

    $Process = [Diagnostics.Process]::new()
    $Process.StartInfo = $StartInfo
    $null = $Process.Start()
    $StdOutTask = $Process.StandardOutput.ReadToEndAsync()
    $StdErrTask = $Process.StandardError.ReadToEndAsync()

    $TimedOut = $false
    if($TimeoutSeconds -gt 0)
    {
      $TimedOut = -not $Process.WaitForExit($TimeoutSeconds * 1000)
    }
    else
    {
      $Process.WaitForExit()
    }

    if($TimedOut)
    {
      & taskkill.exe /PID $Process.Id /T /F 2>$null | Out-Null
      if(-not $Process.HasExited) { try { $Process.Kill() } catch { } }
    }
    $Process.WaitForExit()

    $StdOut = $StdOutTask.Result
    $StdErr = $StdErrTask.Result
    $ExitCode = if($TimedOut) { -1 } else { $Process.ExitCode }
    $Process.Dispose()

    if(-not $TimedOut -and $ExitCode -eq 0)
    {
      return [pscustomobject]@{
        ExitCode = 0
        StdOut = $StdOut
        StdErr = $StdErr
      }
    }

    if($Attempt -lt $MaxAttempts)
    {
      $Reason = if($TimedOut) { "timed out after $TimeoutSeconds seconds" } else { "failed with exit code $ExitCode" }
      Write-Warning "git network operation $Reason (attempt $Attempt/$MaxAttempts); retrying."
      Start-Sleep -Seconds 1
      continue
    }

    if($AllowFailure)
    {
      return [pscustomobject]@{
        ExitCode = $ExitCode
        StdOut = $StdOut
        StdErr = $StdErr
      }
    }

    if($StdErr)
    {
      Write-Error $StdErr.Trim()
    }
    if($TimedOut)
    {
      throw "git $($StartInfo.Arguments) timed out after $MaxAttempts attempts of $TimeoutSeconds seconds"
    }
    throw "git $($StartInfo.Arguments) failed with exit code $ExitCode after $MaxAttempts attempts"
  }
}

function Invoke-DaliGitNetwork
{
  param(
    [Parameter(Mandatory = $true)]
    [string[]]$Arguments,
    [string]$CleanupPathOnRetry = ""
  )

  $NetworkArguments = @(
    "-c", "http.lowSpeedLimit=$DaliNetworkLowSpeedBytesPerSecond",
    "-c", "http.lowSpeedTime=$DaliNetworkTimeoutSeconds"
  ) + $Arguments

  return Invoke-DaliGit -Arguments $NetworkArguments `
    -MaxAttempts $DaliNetworkRetryCount `
    -CleanupPathOnRetry $CleanupPathOnRetry
}
