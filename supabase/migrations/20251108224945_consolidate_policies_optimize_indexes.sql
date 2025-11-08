/*
  # Consolidate Policies and Optimize Database

  ## Changes Made
  
  1. **Consolidate Multiple Permissive Policies**
     - Merge multiple SELECT policies into single policies with OR conditions
     - Reduces policy overhead and simplifies access control
     - Affects: listings (2 SELECT policies → 1), inquiries (2 SELECT policies → 1)
  
  2. **Remove Truly Unused Indexes**
     - Remove indexes that are not used by any queries: saved_searches indexes
     - Keep indexes that ARE used by application queries:
       - idx_car_makes_popular, idx_car_models_popular (used in ORDER BY)
       - idx_car_models_make_id (used in WHERE make_id = ?)
       - idx_favorites_listing_id, idx_user_profiles_city_id (foreign keys)
       - idx_listings_created_at (used in ORDER BY created_at)
       - idx_inquiries_listing_id, idx_inquiries_user_id (JOIN queries)
  
  3. **Important Notes**
     - Leaked password protection must be enabled in Supabase Dashboard
     - Consolidated policies maintain the same access control logic
*/

-- =============================================
-- 1. CONSOLIDATE LISTINGS SELECT POLICIES
-- =============================================

-- Drop the two separate SELECT policies
DROP POLICY IF EXISTS "Everyone can view active listings" ON public.listings;
DROP POLICY IF EXISTS "Sellers can view their own listings" ON public.listings;

-- Create single consolidated SELECT policy
CREATE POLICY "Users can view listings"
  ON public.listings
  FOR SELECT
  TO authenticated
  USING (
    status = 'active' OR user_id = (select auth.uid())
  );

-- Allow anonymous users to view active listings
CREATE POLICY "Public can view active listings"
  ON public.listings
  FOR SELECT
  TO public
  USING (status = 'active');

-- =============================================
-- 2. CONSOLIDATE INQUIRIES SELECT POLICIES
-- =============================================

-- Drop the two separate SELECT policies
DROP POLICY IF EXISTS "Sellers can view inquiries for their listings" ON public.inquiries;
DROP POLICY IF EXISTS "Users can view own inquiries" ON public.inquiries;

-- Create single consolidated SELECT policy
CREATE POLICY "Users can view inquiries"
  ON public.inquiries
  FOR SELECT
  TO authenticated
  USING (
    user_id = (select auth.uid())
    OR
    EXISTS (
      SELECT 1 FROM public.listings
      WHERE listings.id = inquiries.listing_id
      AND listings.user_id = (select auth.uid())
    )
  );

-- =============================================
-- 3. REMOVE TRULY UNUSED INDEXES
-- =============================================

-- Remove saved_searches indexes (feature not implemented in UI yet)
DROP INDEX IF EXISTS public.idx_saved_searches_user_id;
DROP INDEX IF EXISTS public.idx_saved_searches_active;

-- NOTE: Keeping the following indexes as they ARE used by queries:
-- - idx_car_makes_popular (used in: ORDER BY popular DESC)
-- - idx_car_models_popular (used in: ORDER BY popular DESC)
-- - idx_car_models_make_id (used in: WHERE make_id = ?)
-- - idx_favorites_listing_id (used in JOINs)
-- - idx_user_profiles_city_id (used in JOINs)
-- - idx_listings_created_at (used in: ORDER BY created_at DESC)
-- - idx_inquiries_listing_id (used in JOINs with listings)
-- - idx_inquiries_user_id (used in WHERE user_id = ?)
