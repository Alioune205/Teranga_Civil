import { useState, useEffect } from 'react';
import axiosClient from '@/api/axiosClient';

// Global cache for secure images
// Map format: { [url]: { objectUrl: string | null, promise: Promise | null, error: boolean } }
const secureImageCache = new Map();

export function clearSecureImageCache() {
  secureImageCache.forEach(entry => {
    if (entry.objectUrl) {
      URL.revokeObjectURL(entry.objectUrl);
    }
  });
  secureImageCache.clear();
}

export default function useSecureImage(src, shouldFetch = true) {
  const [objectUrl, setObjectUrl] = useState(null);
  const [error, setError] = useState(false);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    if (!src || !shouldFetch) {
      setLoading(false);
      return;
    }

    let isMounted = true;
    setLoading(true);

    const fetchImage = async () => {
      // 1. Check if already cached and resolved
      const cached = secureImageCache.get(src);
      if (cached && cached.objectUrl) {
        if (isMounted) {
          setObjectUrl(cached.objectUrl);
          setError(cached.error);
          setLoading(false);
        }
        return;
      }

      // 2. Check if a request is already in progress for this URL
      if (cached && cached.promise) {
        try {
          const url = await cached.promise;
          if (isMounted) {
            setObjectUrl(url);
            setLoading(false);
          }
        } catch (err) {
          if (isMounted) {
            setError(true);
            setLoading(false);
          }
        }
        return;
      }

      // 3. Initiate a new request and store the promise in the cache
      const fetchPromise = axiosClient.get(src, { responseType: 'blob' })
        .then(res => {
          const url = URL.createObjectURL(res.data);
          secureImageCache.set(src, { objectUrl: url, promise: null, error: false });
          return url;
        })
        .catch(err => {
          console.error('Failed to load secure image', err);
          secureImageCache.set(src, { objectUrl: null, promise: null, error: true });
          throw err;
        });

      secureImageCache.set(src, { objectUrl: null, promise: fetchPromise, error: false });

      try {
        const url = await fetchPromise;
        if (isMounted) {
          setObjectUrl(url);
          setLoading(false);
        }
      } catch (err) {
        if (isMounted) {
          setError(true);
          setLoading(false);
        }
      }
    };

    fetchImage();

    return () => {
      isMounted = false;
    };
  }, [src, shouldFetch]);

  return { objectUrl, error, loading };
}
