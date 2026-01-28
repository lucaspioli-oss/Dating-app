import { useCallback, useRef } from 'react'

// Pattern de vibração de telefone
const PHONE_VIBRATION_PATTERN = [500, 200, 500, 200, 500, 1000] // vibra, pausa, vibra...

export function useVibration() {
  const intervalRef = useRef<ReturnType<typeof setInterval> | null>(null)

  const vibrate = useCallback((pattern: number | number[] = 200) => {
    if ('vibrate' in navigator) {
      navigator.vibrate(pattern)
    }
  }, [])

  const startPhoneVibration = useCallback(() => {
    // Vibra uma vez imediatamente
    vibrate(PHONE_VIBRATION_PATTERN)

    // Continua vibrando em loop
    intervalRef.current = setInterval(() => {
      vibrate(PHONE_VIBRATION_PATTERN)
    }, 3000) // Repete a cada 3 segundos
  }, [vibrate])

  const stopVibration = useCallback(() => {
    if (intervalRef.current) {
      clearInterval(intervalRef.current)
      intervalRef.current = null
    }
    if ('vibrate' in navigator) {
      navigator.vibrate(0) // Para vibração
    }
  }, [])

  return {
    vibrate,
    startPhoneVibration,
    stopVibration
  }
}
