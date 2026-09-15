import 'package:flutter/material.dart';

/// Card typography, shared by every card body.
///
/// The reference is the note grid card: every size below is taken from it, so
/// notes, folders, grid and list all read the same.
const double cardTitleSize = 11.0;
const double cardDateSize = 9.0;
const double cardContentSize = 10.0;
const double cardMetaSize = 9.0;
const double cardMetaIconSize = 11.0;

/// Bold title.
TextStyle cardTitleStyle(Color textColor) => TextStyle(
      fontSize: cardTitleSize,
      fontWeight: FontWeight.bold,
      color: textColor,
    );

/// Muted date.
TextStyle cardDateStyle(Color textColor) =>
    TextStyle(fontSize: cardDateSize, color: textColor.withValues(alpha: 0.6));

/// Muted excerpt.
TextStyle cardContentStyle(Color textColor) => TextStyle(
      fontSize: cardContentSize,
      color: textColor.withValues(alpha: 0.8),
      height: 1.4,
    );

/// Muted metadata (counts).
TextStyle cardMetaStyle(Color textColor) =>
    TextStyle(fontSize: cardMetaSize, color: textColor.withValues(alpha: 0.6));
