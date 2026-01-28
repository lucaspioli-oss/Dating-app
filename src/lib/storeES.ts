import { create } from 'zustand'
import { questionsES, profilesES, type Profile } from './dataES'

interface QuizState {
  currentQuestionIndex: number
  totalScore: number
  answers: Record<number, number>
  matchedProfile: Profile | null
  answerQuestion: (questionId: number, points: number) => void
  nextQuestion: () => boolean
  calculateProfile: () => void
  resetQuiz: () => void
}

export const useQuizStoreES = create<QuizState>((set, get) => ({
  currentQuestionIndex: 0,
  totalScore: 0,
  answers: {},
  matchedProfile: null,

  answerQuestion: (questionId, points) => {
    set((state) => ({
      answers: { ...state.answers, [questionId]: points },
      totalScore: state.totalScore + points,
    }))
  },

  nextQuestion: () => {
    const { currentQuestionIndex } = get()
    if (currentQuestionIndex < questionsES.length - 1) {
      set({ currentQuestionIndex: currentQuestionIndex + 1 })
      return true
    }
    return false
  },

  calculateProfile: () => {
    const { totalScore } = get()
    const profile = profilesES.find(
      (p) => totalScore >= p.minScore && totalScore <= p.maxScore
    )
    set({ matchedProfile: profile || profilesES[profilesES.length - 1] })
  },

  resetQuiz: () => {
    set({
      currentQuestionIndex: 0,
      totalScore: 0,
      answers: {},
      matchedProfile: null,
    })
  },
}))
