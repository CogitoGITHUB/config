import '../styles/globals.css'
import type { AppProps } from 'next/app'
import { ChakraProvider, extendTheme } from '@chakra-ui/react'
import React, { useState, useMemo, useContext } from 'react'

import { ThemeContext } from '../util/themecontext'

class ErrorBoundary extends React.Component<{}, { error: Error | null }> {
  constructor(props: {}) {
    super(props)
    this.state = { error: null }
  }
  static getDerivedStateFromError(error: Error) {
    return { error }
  }
  componentDidCatch(error: Error, errorInfo: React.ErrorInfo) {
    console.error('ErrorBoundary caught', error, errorInfo)
  }
  render() {
    if (this.state.error) {
      return (
        <div style={{ padding: 40, fontFamily: 'monospace', whiteSpace: 'pre-wrap' }}>
          <h2>Client-side exception:</h2>
          <pre style={{ color: 'red' }}>{this.state.error.toString()}</pre>
          <pre style={{ color: '#666', fontSize: 12 }}>{this.state.error.stack}</pre>
        </div>
      )
    }
    return this.props.children
  }
}

function MyApp({ Component, pageProps }: AppProps) {
  const [emacsTheme, setEmacsTheme] = useState<{ [color: string]: string }>({})

  const themeObject = {
    emacsTheme,
    setEmacsTheme,
  }
  return (
    <ErrorBoundary>
      <ThemeContext.Provider value={themeObject}>
        <SubApp>
          <Component {...pageProps} />
        </SubApp>
      </ThemeContext.Provider>
    </ErrorBoundary>
  )
}

function SubApp(props: any) {
  const { children } = props
  const { emacsTheme } = useContext(ThemeContext)
  const themeColors = emacsTheme as { [color: string]: string }

  const theme = useMemo(() => {
    const gray: Record<string, string> = {}
    const grayStops = ['50', '100', '200', '300', '400', '500', '600', '700', '800', '900']
    const grayDefaults = ['#f7fafc', '#f7fafc', '#edf2f7', '#e2e8f0', '#cbd5e0', '#a0aec0', '#718096', '#4a5568', '#2d3748', '#1a202c']
    for (let i = 0; i < grayStops.length; i++) {
      gray[grayStops[i]] = themeColors[`base${i}`] || grayDefaults[i]
    }

    return {
      colors: {
        palette: themeColors,
        white: themeColors['bg'] || '#fff',
        black: themeColors['fg'] || '#000',
        gray,
        red: { 500: themeColors['red'] || '#e53e3e' },
        orange: { 500: themeColors['orange'] || '#dd6b20' },
        yellow: { 500: themeColors['yellow'] || '#d69e2e' },
        green: { 500: themeColors['green'] || '#38a169' },
        cyan: { 500: themeColors['cyan'] || '#00a3c4' },
        blue: { 500: themeColors['blue'] || '#3182ce' },
        teal: { 500: themeColors['blue'] || '#3182ce' },
        purple: { 500: themeColors['violet'] || '#805ad5' },
        pink: { 500: themeColors['magenta'] || '#d53f8c' },
        alt: {
          100: themeColors['bg-alt'] || '#edf2f7',
          900: themeColors['fg-alt'] || '#4a5568',
        },
      },
    }
  }, [JSON.stringify(emacsTheme)])

  const extendedTheme = extendTheme(theme)
  return <ChakraProvider theme={extendedTheme}>{children}</ChakraProvider>
}
export default MyApp
