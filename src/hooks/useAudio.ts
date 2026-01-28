import { useRef, useState, useCallback, useEffect } from 'react'

interface UseAudioOptions {
  onEnded?: () => void
  onTimeUpdate?: (currentTime: number, duration: number) => void
  loop?: boolean
}

export function useAudio(src: string, options: UseAudioOptions = {}) {
  const audioRef = useRef<HTMLAudioElement | null>(null)
  const [isPlaying, setIsPlaying] = useState(false)
  const [currentTime, setCurrentTime] = useState(0)
  const [duration, setDuration] = useState(0)
  const [isLoaded, setIsLoaded] = useState(false)

  useEffect(() => {
    const audio = new Audio(src)
    audio.loop = options.loop || false
    audioRef.current = audio

    const handleLoadedMetadata = () => {
      setDuration(audio.duration)
      setIsLoaded(true)
    }

    const handleTimeUpdate = () => {
      setCurrentTime(audio.currentTime)
      options.onTimeUpdate?.(audio.currentTime, audio.duration)
    }

    const handleEnded = () => {
      setIsPlaying(false)
      options.onEnded?.()
    }

    audio.addEventListener('loadedmetadata', handleLoadedMetadata)
    audio.addEventListener('timeupdate', handleTimeUpdate)
    audio.addEventListener('ended', handleEnded)

    return () => {
      audio.pause()
      audio.removeEventListener('loadedmetadata', handleLoadedMetadata)
      audio.removeEventListener('timeupdate', handleTimeUpdate)
      audio.removeEventListener('ended', handleEnded)
    }
  }, [src])

  const play = useCallback(() => {
    if (audioRef.current) {
      audioRef.current.play()
      setIsPlaying(true)
    }
  }, [])

  const pause = useCallback(() => {
    if (audioRef.current) {
      audioRef.current.pause()
      setIsPlaying(false)
    }
  }, [])

  const stop = useCallback(() => {
    if (audioRef.current) {
      audioRef.current.pause()
      audioRef.current.currentTime = 0
      setIsPlaying(false)
      setCurrentTime(0)
    }
  }, [])

  const seek = useCallback((time: number) => {
    if (audioRef.current) {
      audioRef.current.currentTime = time
      setCurrentTime(time)
    }
  }, [])

  return {
    play,
    pause,
    stop,
    seek,
    isPlaying,
    currentTime,
    duration,
    isLoaded,
    audioRef
  }
}

// Hook simplificado para efeitos sonoros curtos
export function useSoundEffect(src: string) {
  const play = useCallback(() => {
    const audio = new Audio(src)
    audio.play().catch(() => {
      // Ignorar erro se autoplay bloqueado
    })
  }, [src])

  return { play }
}
