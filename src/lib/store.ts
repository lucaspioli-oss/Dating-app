import { create } from 'zustand'
import { questions, profiles, type Profile } from './data'

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

export const useQuizStore = create<QuizState>((set, get) => ({
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
    if (currentQuestionIndex < questions.length - 1) {
      set({ currentQuestionIndex: currentQuestionIndex + 1 })
      return true
    }
    return false
  },

  calculateProfile: () => {
    const { totalScore } = get()
    const profile = profiles.find(
      (p) => totalScore >= p.minScore && totalScore <= p.maxScore
    )
    set({ matchedProfile: profile || profiles[profiles.length - 1] })
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
