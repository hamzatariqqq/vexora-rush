import 'package:flutter/material.dart';

class BallStyle {
  const BallStyle({
    required this.id,
    required this.name,
    required this.price,
    required this.color,
  });

  final String id;
  final String name;
  final int price;
  final Color color;
}

const List<BallStyle> ballStyles = [
  BallStyle(
    id: 'plasma',
    name: 'Plasma',
    price: 0,
    color: Color(0xFF53EAFF),
  ),
  BallStyle(
    id: 'inferno',
    name: 'Inferno',
    price: 600,
    color: Color(0xFFFF5A4F),
  ),
  BallStyle(
    id: 'volt',
    name: 'Volt',
    price: 1200,
    color: Color(0xFFFFFF55),
  ),
  BallStyle(
    id: 'crystal',
    name: 'Crystal',
    price: 2200,
    color: Color(0xFF75E8FF),
  ),
  BallStyle(
    id: 'galaxy',
    name: 'Galaxy',
    price: 3500,
    color: Color(0xFFB76CFF),
  ),
  BallStyle(
    id: 'shadow',
    name: 'Shadow',
    price: 5000,
    color: Color(0xFF8795C9),
  ),
  BallStyle(
    id: 'neon',
    name: 'Neon',
    price: 7000,
    color: Color(0xFF56F59A),
  ),
  BallStyle(
    id: 'ice',
    name: 'Ice',
    price: 9500,
    color: Color(0xFF98EDFF),
  ),
  BallStyle(
    id: 'gold',
    name: 'Gold',
    price: 13000,
    color: Color(0xFFFFC64A),
  ),
];