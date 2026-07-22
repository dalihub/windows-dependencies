#ifndef DALI_WINDOWS_DEPENDENCIES_H
#define DALI_WINDOWS_DEPENDENCIES_H

#include <dali/preprocessor-definitions.h>
#include <dali/extern-definitions.h>

#if defined(_MSC_VER) && !defined(__clang__) && !defined(DALI_MSVC_SYNC_BUILTINS_DEFINED)
#define DALI_MSVC_SYNC_BUILTINS_DEFINED
#include <intrin.h>

template<typename T, typename U>
inline T __sync_fetch_and_add(T* pointer, U value)
{
  static_assert(sizeof(T) == sizeof(long), "MSVC interlocked compatibility requires a 32-bit value");
  return static_cast<T>(_InterlockedExchangeAdd(reinterpret_cast<volatile long*>(pointer), static_cast<long>(value)));
}

template<typename T, typename U>
inline T __sync_fetch_and_sub(T* pointer, U value)
{
  static_assert(sizeof(T) == sizeof(long), "MSVC interlocked compatibility requires a 32-bit value");
  return static_cast<T>(_InterlockedExchangeAdd(reinterpret_cast<volatile long*>(pointer), -static_cast<long>(value)));
}

template<typename T, typename U>
inline T __sync_fetch_and_xor(T* pointer, U value)
{
  static_assert(sizeof(T) == sizeof(long), "MSVC interlocked compatibility requires a 32-bit value");
  return static_cast<T>(_InterlockedXor(reinterpret_cast<volatile long*>(pointer), static_cast<long>(value)));
}

template<typename T, typename U>
inline T __sync_fetch_and_or(T* pointer, U value)
{
  static_assert(sizeof(T) == sizeof(long), "MSVC interlocked compatibility requires a 32-bit value");
  return static_cast<T>(_InterlockedOr(reinterpret_cast<volatile long*>(pointer), static_cast<long>(value)));
}

template<typename T, typename U, typename V>
inline T __sync_val_compare_and_swap(T* pointer, U oldValue, V newValue)
{
  static_assert(sizeof(T) == sizeof(long), "MSVC interlocked compatibility requires a 32-bit value");
  return static_cast<T>(_InterlockedCompareExchange(reinterpret_cast<volatile long*>(pointer), static_cast<long>(newValue), static_cast<long>(oldValue)));
}

template<typename T, typename U, typename V>
inline bool __sync_bool_compare_and_swap(T* pointer, U oldValue, V newValue)
{
  return __sync_val_compare_and_swap(pointer, oldValue, newValue) == static_cast<T>(oldValue);
}

template<typename T, typename U>
inline T __sync_lock_test_and_set(T* pointer, U value)
{
  static_assert(sizeof(T) == sizeof(long), "MSVC interlocked compatibility requires a 32-bit value");
  return static_cast<T>(_InterlockedExchange(reinterpret_cast<volatile long*>(pointer), static_cast<long>(value)));
}
#endif

#endif // DALI_WINDOWS_DEPENDENCIES_H
