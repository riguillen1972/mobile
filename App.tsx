import React, { useState, useRef, useEffect } from 'react';
import {
  StyleSheet,
  View,
  ActivityIndicator,
  StatusBar,
  Platform,
  BackHandler,
  SafeAreaView,
  Text,
} from 'react-native';
import { WebView, WebViewNavigation } from 'react-native-webview';
import * as SplashScreen from 'expo-splash-screen';

// Keep the splash screen visible while loading
SplashScreen.preventAutoHideAsync();

// ---- CHANGE THIS TO YOUR VERCEL URL ----
const APP_URL = 'https://studyssbuddyssai.vercel.app';

export default function App() {
  const [isLoading, setIsLoading] = useState(true);
  const [hasError, setHasError] = useState(false);
  const webViewRef = useRef<WebView>(null);
  const canGoBackRef = useRef(false);

  // Handle Android back button — go back in WebView history
  useEffect(() => {
    if (Platform.OS !== 'android') return;

    const onBackPress = () => {
      if (canGoBackRef.current && webViewRef.current) {
        webViewRef.current.goBack();
        return true; // Prevent default (exit app)
      }
      return false; // Allow default (exit app)
    };

    BackHandler.addEventListener('hardwareBackPress', onBackPress);
    return () => BackHandler.removeEventListener('hardwareBackPress', onBackPress);
  }, []);

  const onNavigationStateChange = (navState: WebViewNavigation) => {
    canGoBackRef.current = navState.canGoBack;
  };

  const handleLoadEnd = () => {
    setIsLoading(false);
    SplashScreen.hideAsync();
  };

  const handleError = () => {
    setHasError(true);
    setIsLoading(false);
    SplashScreen.hideAsync();
  };

  // Inject CSS to hide any elements that shouldn't appear in the app
  // (e.g., "install app" banners, browser-specific elements)
  const injectedJavaScript = `
    (function() {
      // Signal to the web app that it's running inside a native wrapper
      window.__NATIVE_APP__ = true;
      
      // Set viewport meta for proper scaling
      const meta = document.querySelector('meta[name=viewport]');
      if (meta) {
        meta.setAttribute('content', 'width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no');
      }

      // Force dark mode since our splash is dark
      document.documentElement.classList.add('dark');
    })();
    true;
  `;

  if (hasError) {
    return (
      <SafeAreaView style={styles.errorContainer}>
        <StatusBar barStyle="light-content" backgroundColor="#0a0e1a" />
        <Text style={styles.errorEmoji}>📡</Text>
        <Text style={styles.errorTitle}>Connection Error</Text>
        <Text style={styles.errorMessage}>
          Unable to connect to Study Buddy AI. Please check your internet connection and try again.
        </Text>
        <Text
          style={styles.retryButton}
          onPress={() => {
            setHasError(false);
            setIsLoading(true);
          }}
        >
          Try Again
        </Text>
      </SafeAreaView>
    );
  }

  return (
    <View style={styles.container}>
      <StatusBar barStyle="light-content" backgroundColor="#0a0e1a" translucent />

      <WebView
        ref={webViewRef}
        source={{ uri: APP_URL }}
        style={styles.webview}
        onNavigationStateChange={onNavigationStateChange}
        onLoadEnd={handleLoadEnd}
        onError={handleError}
        onHttpError={handleError}
        injectedJavaScript={injectedJavaScript}
        javaScriptEnabled
        domStorageEnabled
        startInLoadingState={false}
        allowsBackForwardNavigationGestures // iOS swipe back
        allowsInlineMediaPlayback
        mediaPlaybackRequiresUserAction={false}
        mixedContentMode="compatibility"
        sharedCookiesEnabled
        thirdPartyCookiesEnabled
        // Handle file uploads (for scan homework)
        allowFileAccess
        allowFileAccessFromFileURLs
        // Pull to refresh
        pullToRefreshEnabled
        // User agent to identify native app on the server
        applicationNameForUserAgent="StudyBuddyNativeApp/1.0"
      />

      {/* Loading overlay */}
      {isLoading && (
        <View style={styles.loadingOverlay}>
          <View style={styles.loadingContent}>
            <Text style={styles.loadingLogo}>📚</Text>
            <Text style={styles.loadingTitle}>Study Buddy AI</Text>
            <ActivityIndicator size="large" color="#6366f1" style={styles.spinner} />
          </View>
        </View>
      )}
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#0a0e1a',
  },
  webview: {
    flex: 1,
    backgroundColor: '#0a0e1a',
    marginTop: Platform.OS === 'android' ? StatusBar.currentHeight || 0 : 0,
  },
  loadingOverlay: {
    ...StyleSheet.absoluteFillObject,
    backgroundColor: '#0a0e1a',
    justifyContent: 'center',
    alignItems: 'center',
    zIndex: 10,
  },
  loadingContent: {
    alignItems: 'center',
  },
  loadingLogo: {
    fontSize: 64,
    marginBottom: 16,
  },
  loadingTitle: {
    color: '#ffffff',
    fontSize: 28,
    fontWeight: '700',
    letterSpacing: -0.5,
    marginBottom: 24,
  },
  spinner: {
    marginTop: 8,
  },
  errorContainer: {
    flex: 1,
    backgroundColor: '#0a0e1a',
    justifyContent: 'center',
    alignItems: 'center',
    paddingHorizontal: 32,
  },
  errorEmoji: {
    fontSize: 64,
    marginBottom: 16,
  },
  errorTitle: {
    color: '#ffffff',
    fontSize: 24,
    fontWeight: '700',
    marginBottom: 12,
  },
  errorMessage: {
    color: '#94a3b8',
    fontSize: 16,
    textAlign: 'center',
    lineHeight: 24,
    marginBottom: 32,
  },
  retryButton: {
    color: '#6366f1',
    fontSize: 18,
    fontWeight: '600',
    paddingVertical: 12,
    paddingHorizontal: 32,
    borderWidth: 1,
    borderColor: '#6366f1',
    borderRadius: 12,
    overflow: 'hidden',
  },
});
