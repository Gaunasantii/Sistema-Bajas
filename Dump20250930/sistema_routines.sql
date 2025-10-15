-- MySQL dump 10.13  Distrib 8.0.36, for Linux (x86_64)
--
-- Host: localhost    Database: sistema
-- ------------------------------------------------------
-- Server version	8.0.43-0ubuntu0.24.04.2

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!50503 SET NAMES utf8 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Temporary view structure for view `usuarios_baja_final`
--

DROP TABLE IF EXISTS `usuarios_baja_final`;
/*!50001 DROP VIEW IF EXISTS `usuarios_baja_final`*/;
SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `usuarios_baja_final` AS SELECT 
 1 AS `Login`,
 1 AS `ultima_fecha`,
 1 AS `estado_mas_reciente`,
 1 AS `baja_final`*/;
SET character_set_client = @saved_cs_client;

--
-- Temporary view structure for view `usuarios_estado`
--

DROP TABLE IF EXISTS `usuarios_estado`;
/*!50001 DROP VIEW IF EXISTS `usuarios_estado`*/;
SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `usuarios_estado` AS SELECT 
 1 AS `Login`,
 1 AS `ultima_fecha`,
 1 AS `estado_mas_reciente`,
 1 AS `baja_por_estado`*/;
SET character_set_client = @saved_cs_client;

--
-- Final view structure for view `usuarios_baja_final`
--

/*!50001 DROP VIEW IF EXISTS `usuarios_baja_final`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_0900_ai_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `usuarios_baja_final` AS select `ue`.`Login` AS `Login`,`ue`.`ultima_fecha` AS `ultima_fecha`,`ue`.`estado_mas_reciente` AS `estado_mas_reciente`,(case when ((`ue`.`baja_por_estado` = 1) or (`ubt`.`Login` is not null) or (`ubm`.`Login` is not null)) then 1 else 0 end) AS `baja_final` from ((`usuarios_estado` `ue` left join `usuarios_BajaTotal` `ubt` on(((`ue`.`Login` collate utf8mb4_general_ci) = (`ubt`.`Login` collate utf8mb4_general_ci)))) left join `usuarios_BajaTotal_Manual` `ubm` on(((`ue`.`Login` collate utf8mb4_general_ci) = (`ubm`.`Login` collate utf8mb4_general_ci)))) */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `usuarios_estado`
--

/*!50001 DROP VIEW IF EXISTS `usuarios_estado`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_0900_ai_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `usuarios_estado` AS select `s`.`Login` AS `Login`,max(`s`.`Fecha Fin`) AS `ultima_fecha`,substring_index(group_concat(`s`.`Estado` order by `s`.`Fecha Fin` DESC separator '|'),'|',1) AS `estado_mas_reciente`,(case when (lower(substring_index(group_concat(`s`.`Estado` order by `s`.`Fecha Fin` DESC separator '|'),'|',1)) in ('servicio eliminado','solicitud resuelta')) then 1 else 0 end) AS `baja_por_estado` from `solicitudes` `s` group by `s`.`Login` */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2025-09-30 12:27:02
