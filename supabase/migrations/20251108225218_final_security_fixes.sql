/*
  # Final Security and Performance Fixes

  ## Changes Made
  
  1. **Add Missing Foreign Key Index**
     - Add index on `saved_searches.user_id` for better query performance
  
  2. **Fix Multiple Permissive Policies on Listings**
     - The issue is that "Public can view active listings" applies to authenticated role too
     - Change the public policy to only apply to anon role
     - Keep "Users can view listings" for authenticated users only
  
  3. **Important Notes on Unused Indexes**
     - Indexes show as "unused" because they haven't been queried yet in production
     - All indexes are strategically placed for:
       - Foreign key constraints (JOIN performance)
       - ORDER BY clauses (sorting performance)
       - WHERE clauses (filter performance)
     - They will be used as the application receives traffic
  
  4. **Leaked Password Protection**
     - Must be manually enabled in Supabase Dashboard → Authentication → Settings
     - Cannot be enabled via SQL migration
*/

-- =============================================
-- 1. ADD MISSING FOREIGN KEY INDEX
-- =============================================

-- Index for saved_searches.user_id foreign key
CREATE INDEX IF NOT EXISTS idx_saved_searches_user_id 
ON public.saved_searches(user_id);

-- =============================================
-- 2. FIX MULTIPLE PERMISSIVE POLICIES
-- =============================================

-- Drop the policy that applies to public (which includes authenticated)
DROP POLICY IF EXISTS "Public can view active listings" ON public.listings;

-- Recreate it to only apply to anonymous users (anon role)
CREATE POLICY "Anonymous can view active listings"
  ON public.listings
  FOR SELECT
  TO anon
  USING (status = 'active');

-- The "Users can view listings" policy remains for authenticated users
-- This eliminates the multiple permissive policies issue

-- =============================================
-- 3. NOTES ON INDEX USAGE
-- =============================================

-- These indexes WILL be used by the following queries:
--
-- idx_car_makes_popular:
--   SELECT * FROM car_makes ORDER BY popular DESC, name ASC
--
-- idx_car_models_popular:
--   SELECT * FROM car_models WHERE make_id = ? ORDER BY popular DESC, name ASC
--
-- idx_car_models_make_id:
--   SELECT * FROM car_models WHERE make_id = ?
--
-- idx_favorites_listing_id:
--   JOIN queries between favorites and listings
--   DELETE FROM favorites WHERE listing_id = ?
--
-- idx_user_profiles_city_id:
--   JOIN queries between user_profiles and cities
--   SELECT * FROM user_profiles JOIN cities ON user_profiles.city_id = cities.id
--
-- idx_listings_created_at:
--   SELECT * FROM listings ORDER BY created_at DESC
--
-- idx_inquiries_listing_id:
--   SELECT * FROM inquiries WHERE listing_id = ?
--   JOIN queries between inquiries and listings
--
-- idx_inquiries_user_id:
--   SELECT * FROM inquiries WHERE user_id = ?
--
-- idx_saved_searches_user_id:
--   SELECT * FROM saved_searches WHERE user_id = ?
