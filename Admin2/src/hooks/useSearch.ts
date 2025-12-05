import { useState, useEffect, useMemo, useCallback } from 'react';

/**
 * Normalize Vietnamese text by removing diacritics/accents
 * "điện thoại" → "dien thoai"
 */
export function normalizeVietnamese(str: string): string {
    if (!str) return '';
    return str
        .normalize('NFD')
        .replace(/[\u0300-\u036f]/g, '') // Remove diacritics
        .replace(/đ/g, 'd')
        .replace(/Đ/g, 'D')
        .toLowerCase();
}

interface UseSearchOptions<T> {
    /** Array of items to search through */
    items: T[];
    /** Fields to search in (supports nested paths like 'userInfo.fullName') */
    searchFields: (keyof T | string)[];
    /** Debounce delay in ms (default: 250) */
    debounceMs?: number;
    /** Enable Vietnamese accent normalization (default: true) */
    enableVietnameseNormalization?: boolean;
    /** Optional category filter field */
    categoryField?: keyof T;
}

interface UseSearchResult<T> {
    /** Current search query */
    query: string;
    /** Set search query */
    setQuery: (value: string) => void;
    /** Current category filter */
    selectedCategory: string;
    /** Set category filter */
    setSelectedCategory: (value: string) => void;
    /** Filtered results after search and category filter */
    filteredItems: T[];
    /** Whether currently debouncing */
    isSearching: boolean;
    /** Clear search and filters */
    clearSearch: () => void;
}

/**
 * Hook for client-side search with debounce, Vietnamese normalization, and category filtering
 */
export function useSearch<T extends Record<string, any>>({
    items,
    searchFields,
    debounceMs = 250,
    enableVietnameseNormalization = true,
    categoryField,
}: UseSearchOptions<T>): UseSearchResult<T> {
    const [query, setQuery] = useState('');
    const [debouncedQuery, setDebouncedQuery] = useState('');
    const [selectedCategory, setSelectedCategory] = useState('');
    const [isSearching, setIsSearching] = useState(false);

    // Debounce the query
    useEffect(() => {
        if (query !== debouncedQuery) {
            setIsSearching(true);
        }

        const handler = setTimeout(() => {
            setDebouncedQuery(query);
            setIsSearching(false);
        }, debounceMs);

        return () => clearTimeout(handler);
    }, [query, debounceMs]);

    // Get nested value from object using dot notation
    const getNestedValue = useCallback((obj: any, path: string): any => {
        return path.split('.').reduce((acc, part) => acc?.[part], obj);
    }, []);

    // Normalize text for comparison
    const normalizeText = useCallback(
        (text: string): string => {
            if (!text) return '';
            const lower = String(text).toLowerCase();
            return enableVietnameseNormalization ? normalizeVietnamese(lower) : lower;
        },
        [enableVietnameseNormalization]
    );

    // Filter items based on debounced query and category
    const filteredItems = useMemo(() => {
        console.log('🔍 [Search] Filtering started');
        console.log('📝 [Search] Current query:', debouncedQuery);
        console.log('📂 [Search] Selected category:', selectedCategory);

        let results = items;

        // 1. Filter by Category first (if applicable)
        if (categoryField && selectedCategory && selectedCategory !== 'all') {
            console.log('🔄 [Search] Applying category filter...');
            results = results.filter(item => {
                const itemCategory = String(item[categoryField]);
                return itemCategory === selectedCategory;
            });
            console.log('📊 [Search] After category filter:', results.length);
        }

        // 2. Filter by Search Query
        if (debouncedQuery.trim()) {
            console.log('🔄 [Search] Applying text search...');
            const normalizedQuery = normalizeText(debouncedQuery);
            console.log('🔄 [Search] Normalized query:', normalizedQuery);

            results = results.filter((item) =>
                searchFields.some((field) => {
                    const value = getNestedValue(item, String(field));
                    if (value == null) return false;
                    const normalizedValue = normalizeText(String(value));
                    const matches = normalizedValue.includes(normalizedQuery);
                    if (matches) {
                        // console.log('✅ [Search] Match found in field:', field, 'value:', value);
                    }
                    return matches;
                })
            );
        } else {
            console.log('✅ [Search] Empty query, skipping text search');
        }

        console.log('📊 [Search] Final filtered results count:', results.length);
        if (results.length > 0) {
            console.log('🎯 [Search] First match:', results[0]);
        } else {
            console.log('⚠️ [Search] No matches found');
        }

        return results;
    }, [items, debouncedQuery, selectedCategory, searchFields, categoryField, normalizeText, getNestedValue]);

    const clearSearch = useCallback(() => {
        setQuery('');
        setDebouncedQuery('');
        setSelectedCategory('');
    }, []);

    return {
        query,
        setQuery,
        selectedCategory,
        setSelectedCategory,
        filteredItems,
        isSearching,
        clearSearch,
    };
}

export default useSearch;
