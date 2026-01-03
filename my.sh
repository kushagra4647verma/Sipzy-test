#!/bin/bash

# Quick Fix Script for Remaining 24 Issues
# Run this in your Flutter project root directory

set -e

echo "🔧 Fixing remaining Flutter analyze issues..."
echo ""

# Count fixes
fix_count=0

# Fix 1: Remove const from Rect.fromLTWH in splash_screen.dart (2 errors)
if grep -q "createShader(const Rect.fromLTWH" lib/features/auth/splash_screen.dart 2>/dev/null; then
    sed -i.bak 's/createShader(const Rect\.fromLTWH/createShader(Rect.fromLTWH/g' lib/features/auth/splash_screen.dart
    echo "✅ Fixed: splash_screen.dart - Removed const from Rect.fromLTWH"
    fix_count=$((fix_count + 2))
fi

# Fix 2: Replace withOpacity with withValues in splash_screen.dart (2 deprecations)
if grep -q "\.withOpacity(" lib/features/auth/splash_screen.dart 2>/dev/null; then
    sed -i.bak 's/\.withOpacity(\([^)]*\))/.withValues(alpha: \1)/g' lib/features/auth/splash_screen.dart
    echo "✅ Fixed: splash_screen.dart - Updated withOpacity to withValues"
    fix_count=$((fix_count + 2))
fi

# Fix 3: Replace (_, __) with meaningful names in app.dart (8 occurrences)
if grep -q "builder: (_, __)" lib/app.dart 2>/dev/null; then
    sed -i.bak 's/builder: (_, __)/builder: (context, state)/g' lib/app.dart
    echo "✅ Fixed: app.dart - Replaced underscores with meaningful names"
    fix_count=$((fix_count + 8))
fi

# Fix 4: Replace (_, __) in splash_screen.dart (2 occurrences)
if grep -q "builder: (_, __)" lib/features/auth/splash_screen.dart 2>/dev/null; then
    sed -i.bak 's/builder: (_, __)/builder: (context, child)/g' lib/features/auth/splash_screen.dart
    echo "✅ Fixed: splash_screen.dart - Replaced underscores"
    fix_count=$((fix_count + 2))
fi

# Fix 5: Replace (_, __) in events_page.dart
if grep -q "itemBuilder: (_, __)" lib/features/events/events_page.dart 2>/dev/null; then
    sed -i.bak 's/itemBuilder: (_, __)/itemBuilder: (context, index)/g' lib/features/events/events_page.dart
    echo "✅ Fixed: events_page.dart - Replaced underscores"
    fix_count=$((fix_count + 1))
fi

# Fix 6: Replace (_, __) in expert_dashboard.dart
if grep -q "separatorBuilder: (_, __)" lib/features/expert/expert_dashboard.dart 2>/dev/null; then
    sed -i.bak 's/separatorBuilder: (_, __)/separatorBuilder: (context, index)/g' lib/features/expert/expert_dashboard.dart
    echo "✅ Fixed: expert_dashboard.dart - Replaced underscores"
    fix_count=$((fix_count + 1))
fi

# Fix 7: Replace (_, __) in games_page.dart
if grep -q "itemBuilder: (_, __)" lib/features/games/games_page.dart 2>/dev/null; then
    sed -i.bak 's/itemBuilder: (_, __)/itemBuilder: (context, index)/g' lib/features/games/games_page.dart
    echo "✅ Fixed: games_page.dart - Replaced underscores"
    fix_count=$((fix_count + 1))
fi

# Fix 8: Replace (_, __) in invite_friends_modal.dart
if grep -q "separatorBuilder: (_, __)" lib/shared/ui/invite_friends_modal.dart 2>/dev/null; then
    sed -i.bak 's/separatorBuilder: (_, __)/separatorBuilder: (context, index)/g' lib/shared/ui/invite_friends_modal.dart
    echo "✅ Fixed: invite_friends_modal.dart - Replaced underscores"
    fix_count=$((fix_count + 1))
fi

# Fix 9: Fix test file
if [ -f "test/widget_test.dart" ]; then
    if grep -q "MyApp" test/widget_test.dart 2>/dev/null; then
        sed -i.bak 's/MyApp/SipZyApp/g' test/widget_test.dart
        echo "✅ Fixed: widget_test.dart - Replaced MyApp with SipZyApp"
        fix_count=$((fix_count + 1))
    fi
fi

# Cleanup backup files
find . -name "*.dart.bak" -type f -delete 2>/dev/null || true

echo ""
echo "📊 Automated fixes: $fix_count issues resolved"
echo ""
echo "⚠️  Manual fixes still required (3 issues):"
echo "   1. lib/features/home/home_page.dart - fetchBookmarks() type casting (2 errors)"
echo "   2. lib/ui/sipzy_button.dart - Remove unreachable default cases (2 warnings)"
echo ""
echo "📝 See REMAINING_FIXES.md for detailed manual fix instructions"
echo ""
echo "Run 'flutter analyze' to check remaining issues"
