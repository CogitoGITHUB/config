import { createContext } from 'react'

type ThemeObject = { [color: string]: string }
export interface ThemeContextProps {
  emacsTheme: ThemeObject
  setEmacsTheme: (theme: ThemeObject) => void
}

const ThemeContext = createContext<ThemeContextProps>({
  emacsTheme: {},
  setEmacsTheme: () => {},
})
export { ThemeContext }
