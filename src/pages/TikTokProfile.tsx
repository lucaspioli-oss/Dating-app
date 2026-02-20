import { useState } from 'react'
import { useLocation } from 'wouter'
import { motion } from 'framer-motion'
import {
  ArrowLeft,
  Bell,
  Share2,
  MoreHorizontal,
  Grid3X3,
  Bookmark,
  Lock,
  Heart,
  Play,
  Home,
  Search,
  Plus,
  MessageCircle,
  User
} from 'lucide-react'

interface VideoThumbnail {
  id: string
  thumbnail: string
  views: string
  url: string
}

// Placeholder - será substituído pelos vídeos reais
const profileVideos: VideoThumbnail[] = [
  { id: '1', thumbnail: '/assets/videos/thumb1.jpg', views: '42.5K', url: '/assets/videos/video1.mp4' },
  { id: '2', thumbnail: '/assets/videos/thumb2.jpg', views: '38.1K', url: '/assets/videos/video2.mp4' },
  { id: '3', thumbnail: '/assets/videos/thumb3.jpg', views: '67.2K', url: '/assets/videos/video3.mp4' },
  { id: '4', thumbnail: '/assets/videos/thumb4.jpg', views: '23.8K', url: '/assets/videos/video4.mp4' },
  { id: '5', thumbnail: '/assets/videos/thumb5.jpg', views: '51.3K', url: '/assets/videos/video5.mp4' },
  { id: '6', thumbnail: '/assets/videos/thumb6.jpg', views: '89.7K', url: '/assets/videos/video6.mp4' },
]

const likedVideos: VideoThumbnail[] = [
  { id: 'l1', thumbnail: '/assets/videos/liked1.jpg', views: '120K', url: '' },
  { id: 'l2', thumbnail: '/assets/videos/liked2.jpg', views: '85K', url: '' },
]

export default function TikTokProfile() {
  const [, setLocation] = useLocation()
  const [activeTab, setActiveTab] = useState<'videos' | 'liked' | 'saved'>('videos')
  const [isFollowing, setIsFollowing] = useState(false)

  const goToFeed = () => {
    setLocation('/tiktok')
  }

  const handleVideoClick = (videoId: string) => {
    // Navega para o feed no vídeo específico
    setLocation(`/tiktok?v=${videoId}`)
  }

  return (
    <div className="min-h-screen bg-black text-white">
      {/* Header */}
      <div className="sticky top-0 bg-black z-20">
        <div className="flex items-center justify-between px-4 py-3">
          <button onClick={goToFeed}>
            <ArrowLeft className="w-6 h-6" />
          </button>
          <h1 className="text-lg font-bold">@neo.desenrola</h1>
          <div className="flex items-center gap-4">
            <Bell className="w-6 h-6" />
            <MoreHorizontal className="w-6 h-6" />
          </div>
        </div>
      </div>

      {/* Profile Info */}
      <div className="px-4 pb-4">
        {/* Avatar */}
        <div className="flex justify-center mb-3">
          <div className="w-24 h-24 rounded-full overflow-hidden border-2 border-white/20">
            <img
              src="/assets/images/NEO-final.png"
              alt="NEO"
              className="w-full h-full object-cover"
            />
          </div>
        </div>

        {/* Username */}
        <div className="text-center mb-4">
          <h2 className="text-base font-semibold">@neo.desenrola</h2>
        </div>

        {/* Stats */}
        <div className="flex justify-center gap-6 mb-4">
          <div className="text-center">
            <p className="text-lg font-bold">127</p>
            <p className="text-xs text-white/60">Seguindo</p>
          </div>
          <div className="text-center">
            <p className="text-lg font-bold">85.2K</p>
            <p className="text-xs text-white/60">Seguidores</p>
          </div>
          <div className="text-center">
            <p className="text-lg font-bold">1.2M</p>
            <p className="text-xs text-white/60">Curtidas</p>
          </div>
        </div>

        {/* Action buttons */}
        <div className="flex justify-center gap-2 mb-4">
          <motion.button
            whileTap={{ scale: 0.95 }}
            onClick={() => setIsFollowing(!isFollowing)}
            className={`px-8 py-2.5 rounded-md font-semibold text-sm ${
              isFollowing
                ? 'bg-[#2F2F2F] text-white'
                : 'bg-[#FE2C55] text-white'
            }`}
          >
            {isFollowing ? 'Seguindo' : 'Seguir'}
          </motion.button>
          <button className="px-4 py-2.5 rounded-md bg-[#2F2F2F]">
            <MessageCircle className="w-5 h-5" />
          </button>
          <button className="px-4 py-2.5 rounded-md bg-[#2F2F2F]">
            <Share2 className="w-5 h-5" />
          </button>
        </div>

        {/* Bio */}
        <div className="text-center text-sm">
          <p className="mb-1">🚀 Transformando suas conversas</p>
          <p className="mb-1">💬 Dicas de como desenrolar nos apps</p>
          <p className="text-[#00F2EA]">🔗 Link na bio</p>
        </div>
      </div>

      {/* Tabs */}
      <div className="sticky top-12 bg-black z-10 border-b border-white/10">
        <div className="flex">
          <button
            onClick={() => setActiveTab('videos')}
            className={`flex-1 py-3 flex justify-center ${
              activeTab === 'videos' ? 'border-b-2 border-white' : ''
            }`}
          >
            <Grid3X3 className={`w-5 h-5 ${activeTab === 'videos' ? 'text-white' : 'text-white/40'}`} />
          </button>
          <button
            onClick={() => setActiveTab('liked')}
            className={`flex-1 py-3 flex justify-center ${
              activeTab === 'liked' ? 'border-b-2 border-white' : ''
            }`}
          >
            <Heart className={`w-5 h-5 ${activeTab === 'liked' ? 'text-white' : 'text-white/40'}`} />
          </button>
          <button
            onClick={() => setActiveTab('saved')}
            className={`flex-1 py-3 flex justify-center ${
              activeTab === 'saved' ? 'border-b-2 border-white' : ''
            }`}
          >
            <Bookmark className={`w-5 h-5 ${activeTab === 'saved' ? 'text-white' : 'text-white/40'}`} />
          </button>
        </div>
      </div>

      {/* Content */}
      <div className="pb-20">
        {activeTab === 'videos' && (
          <div className="grid grid-cols-3 gap-0.5">
            {profileVideos.map((video) => (
              <motion.button
                key={video.id}
                whileTap={{ scale: 0.98 }}
                onClick={() => handleVideoClick(video.id)}
                className="relative aspect-[9/16] bg-[#1A1A1A]"
              >
                {/* Placeholder - quando tiver thumbnails reais */}
                <div className="absolute inset-0 bg-gradient-to-b from-transparent to-black/60" />
                <div className="absolute inset-0 flex items-center justify-center">
                  <Play className="w-8 h-8 text-white/40" fill="currentColor" />
                </div>
                {/* Views */}
                <div className="absolute bottom-1 left-1 flex items-center gap-1">
                  <Play className="w-3 h-3 text-white" fill="white" />
                  <span className="text-white text-xs font-medium">{video.views}</span>
                </div>
              </motion.button>
            ))}
          </div>
        )}

        {activeTab === 'liked' && (
          <div className="grid grid-cols-3 gap-0.5">
            {likedVideos.map((video) => (
              <div
                key={video.id}
                className="relative aspect-[9/16] bg-[#1A1A1A]"
              >
                <div className="absolute inset-0 bg-gradient-to-b from-transparent to-black/60" />
                <div className="absolute inset-0 flex items-center justify-center">
                  <Play className="w-8 h-8 text-white/40" fill="currentColor" />
                </div>
                <div className="absolute bottom-1 left-1 flex items-center gap-1">
                  <Play className="w-3 h-3 text-white" fill="white" />
                  <span className="text-white text-xs font-medium">{video.views}</span>
                </div>
              </div>
            ))}
          </div>
        )}

        {activeTab === 'saved' && (
          <div className="flex flex-col items-center justify-center py-16">
            <Lock className="w-12 h-12 text-white/20 mb-4" />
            <p className="text-white/40 text-sm">Vídeos salvos são privados</p>
          </div>
        )}
      </div>

      {/* Bottom navigation */}
      <div className="fixed bottom-0 left-0 right-0 bg-black border-t border-white/10 z-20">
        <div className="flex items-center justify-around py-2">
          <button onClick={goToFeed} className="flex flex-col items-center gap-1 px-4 py-1">
            <Home className="w-6 h-6 text-white/60" />
            <span className="text-white/60 text-[10px]">Início</span>
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

          <button className="flex flex-col items-center gap-1 px-4 py-1">
            <User className="w-6 h-6 text-white" fill="white" />
            <span className="text-white text-[10px]">Perfil</span>
          </button>
        </div>
      </div>
    </div>
  )
}
