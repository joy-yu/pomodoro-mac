# Design System

All tokens live in `Styles/AppTheme.swift`. Never write inline color literals or animation parameters in view files.

## Color Tokens

### Base palette

| Token | Hex | Usage |
|---|---|---|
| `AppTheme.paper` | #F7F0E8 | Panel backgrounds, card fills |
| `AppTheme.paperShadow` | #D9C7B8 | Inactive indicators, knob shadows |
| `AppTheme.ring` | #FDF8F2 | Light overlay tint, card backgrounds |
| `AppTheme.tomato` | #C6543F | Primary accent, ball surface |
| `AppTheme.tomatoDark` | #9C3D2E | Ball depth, icon foreground on knobs |
| `AppTheme.olive` | #60734B | Secondary accent, trend line |
| `AppTheme.ink` | #35251D | Primary text |
| `AppTheme.muted` | #8C7567 | Secondary text, labels |
| `AppTheme.accent` | alias → tomato | Tint color for controls |
| `AppTheme.secondaryAccent` | alias → olive | |

### Phase accent colors

Used by the progress arc and the cycle indicator bar. Both base and highlight variants are required for the angular gradient.

| Phase | Base | Highlight |
|---|---|---|
| `.work` | `phaseWork` #B8872A | `phaseWorkHigh` #ECC058 |
| `.shortBreak` | `phaseShortBreak` #5E8A58 | `phaseShortBreakHigh` #98C286 |
| `.longBreak` | `phaseLongBreak` #3A7068 | `phaseLongBreakHigh` #6AA898 |

### Tag palette

6 preset hex strings in `AppTheme.TagPalette.hexValues`. Render with `AppTheme.tagColor(for: hex)`.

## Animation Constants

| Constant | Applied to |
|---|---|
| `AppTheme.Animation.knobPress` | Control knob press scale |
| `AppTheme.Animation.knobHover` | Control knob hover scale |
| `AppTheme.Animation.facePress` | Tomato ball press scale |
| `AppTheme.Animation.progressRing` | Progress arc trim change |
| `AppTheme.Animation.innerFaceHover` | Inner sphere highlight fade |
| `AppTheme.Animation.hoverOverlay` | Play/pause overlay fade in/out |
| `AppTheme.Animation.symbolSwitch` | SF Symbol swap spring |

## Reusable ViewModifiers & Styles

| API | What it provides |
|---|---|
| `.paperPanel()` | Rounded rect paper background + white stroke border |
| `.knobSurface(isPressed:isHovered:)` | Gradient sphere + directional shadow |
| `KnobButtonStyle(size:)` | Full button style with internal hover state |
| `KnobControlSize.regular` | diameter 46 pt, icon 18 pt |
| `KnobControlSize.compact` | diameter 34 pt, icon 13 pt |

## Timer Face Sizing

All numeric sizing for `TimerFaceView` is parameterized through `TimerFaceMetrics`. Never hardcode point values in timer face views.

```swift
let metrics: TimerFaceMetrics = displayMode == .regular ? .regular : .compact
```

Two presets: `TimerFaceMetrics.regular` (menu bar panel) and `TimerFaceMetrics.compact` (floating panel).
