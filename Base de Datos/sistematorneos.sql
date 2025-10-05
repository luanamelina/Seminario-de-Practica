-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Servidor: 127.0.0.1
-- Tiempo de generación: 05-10-2025 a las 01:36:58
-- Versión del servidor: 10.4.32-MariaDB
-- Versión de PHP: 8.2.12

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Base de datos: `sistematorneos`
--
CREATE DATABASE IF NOT EXISTS `sistematorneos` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
USE `sistematorneos`;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `clasificacion`
--

CREATE TABLE `clasificacion` (
  `torneo_id` bigint(20) NOT NULL,
  `usuario_id` bigint(20) NOT NULL,
  `puntos` int(11) NOT NULL DEFAULT 0,
  `posicion` int(11) DEFAULT NULL,
  `activo` tinyint(1) NOT NULL DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `inscripcion`
--

CREATE TABLE `inscripcion` (
  `torneo_id` bigint(20) NOT NULL,
  `usuario_id` bigint(20) NOT NULL,
  `seeding` int(11) DEFAULT NULL,
  `check_in` tinyint(1) NOT NULL DEFAULT 0,
  `activo` tinyint(1) NOT NULL DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `match_`
--

CREATE TABLE `match_` (
  `id` bigint(20) NOT NULL,
  `ronda_id` bigint(20) NOT NULL,
  `mesa` int(11) DEFAULT NULL,
  `player1_id` bigint(20) NOT NULL,
  `player2_id` bigint(20) DEFAULT NULL,
  `p1_wins` tinyint(4) NOT NULL DEFAULT 0,
  `p2_wins` tinyint(4) NOT NULL DEFAULT 0,
  `resultado` enum('P1','P2','EMPATE','BYE','PENDIENTE') NOT NULL DEFAULT 'PENDIENTE',
  `ganador_id` bigint(20) DEFAULT NULL,
  `next_match_id` bigint(20) DEFAULT NULL,
  `next_slot` tinyint(4) DEFAULT NULL,
  `observaciones` varchar(255) DEFAULT NULL,
  `activo` tinyint(1) NOT NULL DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `ronda`
--

CREATE TABLE `ronda` (
  `id` bigint(20) NOT NULL,
  `torneo_id` bigint(20) NOT NULL,
  `numero` int(11) NOT NULL,
  `estado` enum('PENDIENTE','EN_CURSO','CERRADA') NOT NULL DEFAULT 'PENDIENTE',
  `inicio` datetime DEFAULT NULL,
  `activo` tinyint(1) NOT NULL DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `torneo`
--

CREATE TABLE `torneo` (
  `id` bigint(20) NOT NULL,
  `nombre` varchar(120) NOT NULL,
  `modalidad` enum('SUIZO','ROUND_ROBIN','BRACKET') NOT NULL,
  `estado` enum('PENDIENTE','EN_CURSO','FINALIZADO') NOT NULL DEFAULT 'PENDIENTE',
  `inicio` datetime DEFAULT NULL,
  `max_jugadores` int(11) DEFAULT NULL,
  `activo` tinyint(1) NOT NULL DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `usuario`
--

CREATE TABLE `usuario` (
  `id` bigint(20) NOT NULL,
  `nombres` varchar(80) NOT NULL,
  `apellidos` varchar(80) NOT NULL,
  `email` varchar(120) NOT NULL,
  `usuario` varchar(60) NOT NULL,
  `password_hash` varchar(200) NOT NULL,
  `es_admin` tinyint(1) NOT NULL DEFAULT 0,
  `activo` tinyint(1) NOT NULL DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Índices para tablas volcadas
--

--
-- Indices de la tabla `clasificacion`
--
ALTER TABLE `clasificacion`
  ADD PRIMARY KEY (`torneo_id`,`usuario_id`),
  ADD KEY `usuario_id` (`usuario_id`),
  ADD KEY `idx_orden` (`torneo_id`,`puntos`);

--
-- Indices de la tabla `inscripcion`
--
ALTER TABLE `inscripcion`
  ADD PRIMARY KEY (`torneo_id`,`usuario_id`),
  ADD KEY `usuario_id` (`usuario_id`);

--
-- Indices de la tabla `match_`
--
ALTER TABLE `match_`
  ADD PRIMARY KEY (`id`),
  ADD KEY `player2_id` (`player2_id`),
  ADD KEY `ganador_id` (`ganador_id`),
  ADD KEY `next_match_id` (`next_match_id`),
  ADD KEY `idx_ronda` (`ronda_id`),
  ADD KEY `idx_jugadores` (`player1_id`,`player2_id`);

--
-- Indices de la tabla `ronda`
--
ALTER TABLE `ronda`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `torneo_id` (`torneo_id`,`numero`);

--
-- Indices de la tabla `torneo`
--
ALTER TABLE `torneo`
  ADD PRIMARY KEY (`id`);

--
-- Indices de la tabla `usuario`
--
ALTER TABLE `usuario`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `email` (`email`),
  ADD UNIQUE KEY `usuario` (`usuario`);

--
-- AUTO_INCREMENT de las tablas volcadas
--

--
-- AUTO_INCREMENT de la tabla `match_`
--
ALTER TABLE `match_`
  MODIFY `id` bigint(20) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `ronda`
--
ALTER TABLE `ronda`
  MODIFY `id` bigint(20) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `torneo`
--
ALTER TABLE `torneo`
  MODIFY `id` bigint(20) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `usuario`
--
ALTER TABLE `usuario`
  MODIFY `id` bigint(20) NOT NULL AUTO_INCREMENT;

--
-- Restricciones para tablas volcadas
--

--
-- Filtros para la tabla `clasificacion`
--
ALTER TABLE `clasificacion`
  ADD CONSTRAINT `clasificacion_ibfk_1` FOREIGN KEY (`torneo_id`) REFERENCES `torneo` (`id`),
  ADD CONSTRAINT `clasificacion_ibfk_2` FOREIGN KEY (`usuario_id`) REFERENCES `usuario` (`id`);

--
-- Filtros para la tabla `inscripcion`
--
ALTER TABLE `inscripcion`
  ADD CONSTRAINT `inscripcion_ibfk_1` FOREIGN KEY (`torneo_id`) REFERENCES `torneo` (`id`),
  ADD CONSTRAINT `inscripcion_ibfk_2` FOREIGN KEY (`usuario_id`) REFERENCES `usuario` (`id`);

--
-- Filtros para la tabla `match_`
--
ALTER TABLE `match_`
  ADD CONSTRAINT `match__ibfk_1` FOREIGN KEY (`ronda_id`) REFERENCES `ronda` (`id`),
  ADD CONSTRAINT `match__ibfk_2` FOREIGN KEY (`player1_id`) REFERENCES `usuario` (`id`),
  ADD CONSTRAINT `match__ibfk_3` FOREIGN KEY (`player2_id`) REFERENCES `usuario` (`id`),
  ADD CONSTRAINT `match__ibfk_4` FOREIGN KEY (`ganador_id`) REFERENCES `usuario` (`id`),
  ADD CONSTRAINT `match__ibfk_5` FOREIGN KEY (`next_match_id`) REFERENCES `match_` (`id`);

--
-- Filtros para la tabla `ronda`
--
ALTER TABLE `ronda`
  ADD CONSTRAINT `ronda_ibfk_1` FOREIGN KEY (`torneo_id`) REFERENCES `torneo` (`id`);
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
