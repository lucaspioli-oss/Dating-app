import { useState, useRef, useEffect } from 'react'
import { useLocation } from 'wouter'
import { motion, AnimatePresence } from 'framer-motion'
import {
  Heart,
  MessageCircle,
  Share2,
  Music2,
  Plus,
  Home,
  Search,
  User,
  Bookmark
} from 'lucide-react'

interface Video {
  id: string
  url: string
  poster?: string
  username: string
  userAvatar: string
  description: string
  music: string
  likes: string
  comments: string
  shares: string
  isFollowing?: boolean
}

// Placeholder videos - será substituído pelos vídeos reais
const videos: Video[] = [
  {
    id: '1',
    url: '/assets/videos/video1.mp4',
    username: 'neo.desenrola',
    userAvatar: '/assets/images/NEO.png',
    description: 'O segredo que ninguém te conta sobre conversas... 🔥 #desenrola #dicas',
    music: 'som original - neo.desenrola',
    likes: '42.5K',
    comments: '1.2K',
    shares: '892'
  },
  {
    id: '2',
    url: '/assets/videos/video2.mp4',
    username: 'neo.desenrola',
    userAvatar: '/assets/images/NEO.png',
    description: 'Teste isso no próximo match 👀 #conversas #dating',
    music: 'som original - neo.desenrola',
    likes: '38.1K',
    comments: '956',
    shares: '1.1K'
  },
  {
    id: '3',
    url: '/assets/videos/video3.mp4',
    username: 'neo.desenrola',
    userAvatar: '/assets/images/NEO.png',
    description: 'Por que suas conversas morrem? A resposta vai te surpreender 💀',
    music: 'som original - neo.desenrola',
    likes: '67.2K',
    comments: '2.3K',
    shares: '1.8K'
  }
]

export default function TikTokFeed() {
  const [, setLocation] = useLocation()
  const [currentIndex, setCurrentIndex] = useState(0)
  const [likedVideos, setLikedVideos] = useState<Set<string>>(new Set())
  const [isPlaying, setIsPlaying] = useState(true)
  const containerRef = useRef<HTMLDivElement>(null)
  const videoRefs = useRef<(HTMLVideoElement | null)[]>([])

  useEffect(() => {
    // Pausa todos os vídeos exceto o atual
    videoRefs.current.forEach((video, index) => {
      if (video) {
        if (index === currentIndex && isPlaying) {
          video.play().catch(() => {})
        } else {
          video.pause()
        }
      }
    })
  }, [currentIndex, isPlaying])

  const handleScroll = (e: React.UIEvent<HTMLDivElement>) => {
    const container = e.currentTarget
    const scrollTop = container.scrollTop
    const videoHeight = container.clientHeight
    const newIndex = Math.round(scrollTop / videoHeight)

    if (newIndex !== currentIndex && newIndex >= 0 && newIndex < videos.length) {
      setCurrentIndex(newIndex)
    }
  }

  const handleLike = (videoId: string) => {
    setLikedVideos(prev => {
      const newSet = new Set(prev)
      if (newSet.has(videoId)) {
        newSet.delete(videoId)
      } else {
        newSet.add(videoId)
      }
      return newSet
    })
  }

  const handleVideoTap = () => {
    setIsPlaying(prev => !prev)
  }

  const goToProfile = () => {
    setLocation('/game/tiktok/perfil')
  }

  return (
    <div className="h-screen w-full bg-black overflow-hidden relative">
      {/* Videos Container */}
      <div
        ref={containerRef}
        onScroll={handleScroll}
        className="h-full w-full overflow-y-scroll snap-y snap-mandatory"
        style={{ scrollSnapType: 'y mandatory' }}
      >
        {videos.map((video, index) => (
          <div
            key={video.id}
            className="h-screen w-full snap-start relative flex items-center justify-center"
            style={{ scrollSnapAlign: 'start' }}
          >
            {/* Video */}
            <video
              ref={el => videoRefs.current[index] = el}
              src={video.url}
              poster={video.poster}
              loop
              playsInline
              muted={false}
              onClick={handleVideoTap}
              className="h-full w-full object-cover"
            />

            {/* Play/Pause indicator */}
            <AnimatePresence>
              {!isPlaying && currentIndex === index && (
                <motion.div
                  initial={{ opacity: 0, scale: 0.5 }}
                  animate={{ opacity: 1, scale: 1 }}
                  exit={{ opacity: 0, scale: 0.5 }}
                  className="absolute inset-0 flex items-center justify-center pointer-events-none"
                >
                  <div className="w-20 h-20 bg-black/40 rounded-full flex items-center justify-center">
                    <div className="w-0 h-0 border-t-[15px] border-t-transparent border-l-[25px] border-l-white border-b-[15px] border-b-transparent ml-2" />
                  </div>
                </motion.div>
              )}
            </AnimatePresence>

            {/* Right sidebar actions */}
            <div className="absolute right-3 bottom-32 flex flex-col items-center gap-5">
              {/* Profile */}
              <div className="relative" onClick={goToProfile}>
                <div className="w-12 h-12 rounded-full border-2 border-white overflow-hidden">
                  <img
                    src={video.userAvatar}
                    alt={video.username}
                    className="w-full h-full object-cover"
                  />
                </div>
                <div className="absolute -bottom-2 left-1/2 -translate-x-1/2 w-5 h-5 bg-[#FE2C55] rounded-full flex items-center justify-center">
                  <Plus className="w-3 h-3 text-white" />
                </div>
              </div>

              {/* Like */}
              <button
                onClick={() => handleLike(video.id)}
                className="flex flex-col items-center"
              >
                <div className="w-12 h-12 flex items-center justify-center">
                  <Heart
                    className={`w-8 h-8 ${likedVideos.has(video.id) ? 'fill-[#FE2C55] text-[#FE2C55]' : 'text-white'}`}
                  />
                </div>
                <span className="text-white text-xs font-semibold">{video.likes}</span>
              </button>

              {/* Comments */}
              <button className="flex flex-col items-center">
                <div className="w-12 h-12 flex items-center justify-center">
                  <MessageCircle className="w-8 h-8 text-white" />
                </div>
                <span className="text-white text-xs font-semibold">{video.comments}</span>
              </button>

              {/* Bookmark */}
              <button className="flex flex-col items-center">
                <div className="w-12 h-12 flex items-center justify-center">
                  <Bookmark className="w-7 h-7 text-white" />
                </div>
                <span className="text-white text-xs font-semibold">Salvar</span>
              </button>

              {/* Share */}
              <button className="flex flex-col items-center">
                <div className="w-12 h-12 flex items-center justify-center">
                  <Share2 className="w-7 h-7 text-white" />
                </div>
                <span className="text-white text-xs font-semibold">{video.shares}</span>
              </button>

              {/* Music disc */}
              <motion.div
                animate={{ rotate: isPlaying ? 360 : 0 }}
                transition={{ duration: 3, repeat: Infinity, ease: 'linear' }}
                className="w-12 h-12 rounded-full bg-gradient-to-br from-gray-800 to-gray-900 border-4 border-gray-700 flex items-center justify-center"
              >
                <div className="w-5 h-5 rounded-full overflow-hidden">
                  <img
                    src={video.userAvatar}
                    alt="music"
                    className="w-full h-full object-cover"
                  />
                </div>
              </motion.div>
            </div>

            {/* Bottom info */}
            <div className="absolute left-4 right-20 bottom-20">
              {/* Username */}
              <button onClick={goToProfile} className="flex items-center gap-2 mb-2">
                <span className="text-white font-bold text-base">@{video.username}</span>
              </button>

              {/* Description */}
              <p className="text-white text-sm mb-3 line-clamp-2">
                {video.description}
              </p>

              {/* Music */}
              <div className="flex items-center gap-2">
                <Music2 className="w-4 h-4 text-white" />
                <div className="overflow-hidden max-w-[200px]">
                  <motion.p
                    animate={{ x: [0, -100, 0] }}
                    transition={{ duration: 8, repeat: Infinity, ease: 'linear' }}
                    className="text-white text-sm whitespace-nowrap"
                  >
                    {video.music}
                  </motion.p>
                </div>
              </div>
            </div>
          </div>
        ))}
      </div>

      {/* Top header */}
      <div className="absolute top-0 left-0 right-0 z-10">
        <div className="flex items-center justify-center gap-6 pt-4 pb-2">
          <button className="text-white/60 text-base font-semibold">Seguindo</button>
          <span className="text-white/30">|</span>
          <button className="text-white text-base font-bold">Para você</button>
        </div>
      </div>

      {/* Bottom navigation */}
      <div className="absolute bottom-0 left-0 right-0 bg-black border-t border-white/10 z-10">
        <div className="flex items-center justify-around py-2">
          <button className="flex flex-col items-center gap-1 px-4 py-1">
            <Home className="w-6 h-6 text-white" fill="white" />
            <span className="text-white text-[10px]">Início</span>
          </button>

          <button className="flex flex-col items-center gap-1 px-4 py-1">
            <Search className="w-6 h-6 text-white/60" />
            <span className="text-white/60 text-[10px]">Descobrir</span>
          </button>

          {/* Create button */}
          <button className="px-4">
            <div className="w-12 h-8 bg-white rounded-lg flex items-center justify-center relative overflow-hidden">
              <div className="absolute left-0 top-0 bottom-0 w-4 bg-[#00F2EA] rounded-l-lg" />
              <div className="absolute right-0 top-0 bottom-0 w-4 bg-[#FE2C55] rounded-r-lg" />
              <Plus className="w-5 h-5 text-black relative z-10" />
            </div>
          </button>

          <button className="flex flex-col items-center gap-1 px-4 py-1">
            <MessageCircle className="w-6 h-6 text-white/60" />
            <span className="text-white/60 text-[10px]">Caixa</span>
          </button>

          <button
            onClick={goToProfile}
            className="flex flex-col items-center gap-1 px-4 py-1"
          >
            <User className="w-6 h-6 text-white/60" />
            <span className="text-white/60 text-[10px]">Perfil</span>
          </button>
        </div>
      </div>
    </div>
  )
}
