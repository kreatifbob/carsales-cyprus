/*
  # Fix Security and Performance Issues

  ## Changes Made
  
  1. **Missing Indexes for Foreign Keys**
     - Add index on `favorites.listing_id` for better query performance
     - Add index on `user_profiles.city_id` for better query performance
  
  2. **Optimize RLS Policies**
     - Replace `auth.uid()` with `(select auth.uid())` in all RLS policies
     - This prevents re-evaluation for each row, improving performance at scale
     - Affects tables: listings, favorites, user_profiles, inquiries, saved_searches
  
  3. **Important Notes**
     - Unused indexes are kept as they will be used in future queries
     - Multiple permissive policies are intentional for flexible access control
     - Leaked password protection should be enabled in Auth settings (not via SQL)
*/

-- =============================================
-- 1. ADD MISSING INDEXES
-- =============================================

-- Index for favorites.listing_id foreign key
CREATE INDEX IF NOT EXISTS idx_favorites_listing_id 
ON public.favorites(listing_id);

-- Index for user_profiles.city_id foreign key
CREATE INDEX IF NOT EXISTS idx_user_profiles_city_id 
ON public.user_profiles(city_id);

-- =============================================
-- 2. OPTIMIZE RLS POLICIES - LISTINGS TABLE
-- =============================================

-- Drop existing policies
DROP POLICY IF EXISTS "Sellers can view their own listings" ON public.listings;
DROP POLICY IF EXISTS "Sellers can create listings" ON public.listings;
DROP POLICY IF EXISTS "Sellers can update own listings" ON public.listings;
DROP POLICY IF EXISTS "Sellers can delete own listings" ON public.listings;

-- Recreate with optimized auth.uid() calls
CREATE POLICY "Sellers can view their own listings"
  ON public.listings
  FOR SELECT
  TO authenticated
  USING (user_id = (select auth.uid()));

CREATE POLICY "Sellers can create listings"
  ON public.listings
  FOR INSERT
  TO authenticated
  WITH CHECK (user_id = (select auth.uid()));

CREATE POLICY "Sellers can update own listings"
  ON public.listings
  FOR UPDATE
  TO authenticated
  USING (user_id = (select auth.uid()))
  WITH CHECK (user_id = (select auth.uid()));

CREATE POLICY "Sellers can delete own listings"
  ON public.listings
  FOR DELETE
  TO authenticated
  USING (user_id = (select auth.uid()));

-- =============================================
-- 3. OPTIMIZE RLS POLICIES - FAVORITES TABLE
-- =============================================

-- Drop existing policies
DROP POLICY IF EXISTS "Users can manage own favorites" ON public.favorites;
DROP POLICY IF EXISTS "Users can create favorites" ON public.favorites;
DROP POLICY IF EXISTS "Users can delete own favorites" ON public.favorites;

-- Recreate with optimized auth.uid() calls
CREATE POLICY "Users can manage own favorites"
  ON public.favorites
  FOR SELECT
  TO authenticated
  USING (user_id = (select auth.uid()));

CREATE POLICY "Users can create favorites"
  ON public.favorites
  FOR INSERT
  TO authenticated
  WITH CHECK (user_id = (select auth.uid()));

CREATE POLICY "Users can delete own favorites"
  ON public.favorites
  FOR DELETE
  TO authenticated
  USING (user_id = (select auth.uid()));

-- =============================================
-- 4. OPTIMIZE RLS POLICIES - USER_PROFILES TABLE
-- =============================================

-- Drop existing policies
DROP POLICY IF EXISTS "Users can update own profile" ON public.user_profiles;
DROP POLICY IF EXISTS "Users can insert own profile" ON public.user_profiles;

-- Recreate with optimized auth.uid() calls
CREATE POLICY "Users can update own profile"
  ON public.user_profiles
  FOR UPDATE
  TO authenticated
  USING (id = (select auth.uid()))
  WITH CHECK (id = (select auth.uid()));

CREATE POLICY "Users can insert own profile"
  ON public.user_profiles
  FOR INSERT
  TO authenticated
  WITH CHECK (id = (select auth.uid()));

-- =============================================
-- 5. OPTIMIZE RLS POLICIES - INQUIRIES TABLE
-- =============================================

-- Drop existing policies
DROP POLICY IF EXISTS "Sellers can view inquiries for their listings" ON public.inquiries;
DROP POLICY IF EXISTS "Users can view own inquiries" ON public.inquiries;

-- Recreate with optimized auth.uid() calls
CREATE POLICY "Sellers can view inquiries for their listings"
  ON public.inquiries
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.listings
      WHERE listings.id = inquiries.listing_id
      AND listings.user_id = (select auth.uid())
    )
  );

CREATE POLICY "Users can view own inquiries"
  ON public.inquiries
  FOR SELECT
  TO authenticated
  USING (user_id = (select auth.uid()));

-- =============================================
-- 6. OPTIMIZE RLS POLICIES - SAVED_SEARCHES TABLE
-- =============================================

-- Drop existing policies
DROP POLICY IF EXISTS "Users can view own saved searches" ON public.saved_searches;
DROP POLICY IF EXISTS "Users can create own saved searches" ON public.saved_searches;
DROP POLICY IF EXISTS "Users can update own saved searches" ON public.saved_searches;
DROP POLICY IF EXISTS "Users can delete own saved searches" ON public.saved_searches;

-- Recreate with optimized auth.uid() calls
CREATE POLICY "Users can view own saved searches"
  ON public.saved_searches
  FOR SELECT
  TO authenticated
  USING (user_id = (select auth.uid()));

CREATE POLICY "Users can create own saved searches"
  ON public.saved_searches
  FOR INSERT
  TO authenticated
  WITH CHECK (user_id = (select auth.uid()));

CREATE POLICY "Users can update own saved searches"
  ON public.saved_searches
  FOR UPDATE
  TO authenticated
  USING (user_id = (select auth.uid()))
  WITH CHECK (user_id = (select auth.uid()));

CREATE POLICY "Users can delete own saved searches"
  ON public.saved_searches
  FOR DELETE
  TO authenticated
  USING (user_id = (select auth.uid()));
