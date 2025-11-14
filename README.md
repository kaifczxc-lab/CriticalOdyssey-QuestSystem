# CriticalOdyssey-QuestSystem
A ready-to-use, server-side Quest System for Roblox MMORPGs.  Simple to integrate, easy to extend. Supports kill and gathering quests, full requirement validation (level, items, currency), damage-based progress tracking, reward handling (EXP, reputation, gold), and configurable cooldowns.

## Overview

This quest system provides complete infrastructure for managing player quests in Roblox games. It handles quest progression, reward distribution, requirement validation, and real-time UI updates.

## Core Features

### Quest Types
- Kill Quests - Defeat specific enemies or mobs
- Gathering Quests - Collect items and resources
- Extensible architecture for adding new quest types

### Smart Progress Tracking
- Damage-based progression tracking
- Multiple player contribution support
- Prevents quest stealing by tracking actual damage dealers

### Comprehensive Requirements System
- Level requirements
- Item inventory checks
- Gold cost validation
- Class restrictions
- Damage stat requirements
- Cooldown management between quest attempts

### Reward System
- Item rewards (Active, Passive, Materials)
- Gold currency rewards
- Reputation system integration
- Experience points
- Configurable reward structures

### UI System
- Dynamic quest tracker generation
- Real-time progress updates
- Custom UI compatibility
- Error messaging and cooldown displays

---

## Technical Architecture

### QuestServer (Server-Side)
The main server script that handles all quest logic:

- Player quest state management
- Requirement validation before quest start
- Progress tracking for kill and gathering quests
- Reward distribution upon completion
- Cooldown enforcement between quests
- Secure server-side verification

### QuestGUI (Client-Side)
Client interface for displaying quest information:

- Automatic UI generation for quest tracking
- Progress bar updates in real-time
- Completion state visual feedback
- Error message display from server
