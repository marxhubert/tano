# TanoNote UI Design Tokens

This document centralizes all the design values used across the application to ensure consistency and facilitate future maintenance.

## 🎨 Branding & Colors (60/30/10 Rule)
*   **Primary (30%)**: `tanoTeal` (`#009688`) - Used for AppBar, FAB, active states.
*   **Secondary (10%)**: `tanoAmber` (`#FF9800`) - Used for bookmarks, active menu icons, and validation.
*   **Background (60%)**: 
    *   Light: `#F8F9FA`
    *   Dark: `#121212`
    *   Editor (Light): `Colors.white`
    *   Editor (Dark): `#1E1E1E`
*   **Section Background (Light Mode)**: `Colors.black.withValues(alpha: 0.06)` - Used for Settings cards to ensure visibility.

---

## 📏 Dimensions & Layout
| Property | Value | Context |
| :--- | :--- | :--- |
| `appPaddingLarge` | **18.0** | Title margins, Home content horizontal padding, Settings padding |
| `appPaddingMedium` | **12.0** | Card spacing, vertical title padding |
| `appPaddingSmall` | **6.0** | AppBar icon margins |
| `appBorderRadius` | **12.0** | Standard Note Cards, Popup menus, Mockups |
| `sectionBorderRadius` | **18.0** | Settings sections/cards, AppFab (Open) |
| `menuMinWidth` | **160.0** | Minimum width for AppBar PopupMenu |

---

## 🔡 Typography & Weights
| Element | Size | Weight | Color |
| :--- | :--- | :--- | :--- |
| **Big Title (Body)** | 24.0 | `w800` | `primaryTextColor` (-2.0 letterSpacing) |
| **AppBar Title** | 18.0 | `w800` | `primaryTextColor` (-1.0 letterSpacing) |
| **Functional Labels** | 14.0 | `Normal` / `Bold` (Active) | `primaryTextColor` (Menus, Settings, FAB items) |
| **Selection Labels** | 10.0 | `Bold` | `effectiveColor` (AppFab Bottom Bar) |
| **Note Card Title** | 12.0 (List) / 11.0 (Grid) | `Bold` | `getTextColor(bgColor)` |
| **Note Card Date** | 9.0 (List) / 8.0 (Grid) | `w800` | `textColor (0.6 opacity)` |
| **Note Card Body** | 12.0 (List) / 10.0 (Grid) | `Normal` | `textColor (0.8 opacity)` |
| **Description Text** | 12.0 / 13.0 | `Normal` | `mutedTextColor` (1.4 height) |

---

## 🔘 Icons
| Element | Size | Context |
| :--- | :--- | :--- |
| **AppFab Main Icons** | 24.0 | Add, Search, Selection, More |
| **AppBar Actions** | 22.0 | Search, Theme Toggle, More |
| **Indicators** | 20.0 | `check_circle` (Settings, Popup menus) |
| **Note Card Bookmark**| 22.0 | Top-right indicator (Harmonized) |
| **Selection Check** | 24.0 | `check_circle` (Selection mode) |

---

## 📑 Menus & Navigation
| Property | Value | Context |
| :--- | :--- | :--- |
| **Item Height** | **38.0** | Vertical clickable area for all menus (Popup & Settings) |
| **Horizontal Padding**| **16.0** | Internal padding for menu items and tiles |
| **AppFab Menu Height**| **210.0** (Theme) / **180.0** (Add) / **310.0** (More) | Vertical expansion |
| **Visual Density** | `-4.0` | Applied to all menu items for maximum compactness |
| **Switch Scale** | `0.8` | Adaptive switch size in Settings |
| **AppBar Offset** | `56.0` | Vertical space before showing PopupMenu |

---

## 📱 Platform Specifics (iOS Inspirations)
*   **Adaptive Switch**: Uses `Switch.adaptive` for native look.
*   **Back Button**: Uses `Icons.arrow_back_ios_new` (Size 20.0).
*   **Squircle Curves**: Applied to AppFab (18.0) and Settings (18.0) for a premium feel.
*   **Dynamic Island Mockup**: Width 16.0, Height 5.0 (Settings preview).
