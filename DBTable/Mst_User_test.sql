-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- ホスト: 127.0.0.1
-- 生成日時: 2025-09-26 14:02:45
-- サーバのバージョン： 10.4.32-MariaDB
-- PHP のバージョン: 8.2.12

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- データベース: `worth-sc_shiori_test`
--

-- --------------------------------------------------------

--
-- テーブルの構造 `mst_user`
--

CREATE TABLE `mst_user` (
  `UserId` bigint(20) NOT NULL,
  `EmailAddress` varchar(256) DEFAULT NULL,
  `Password` varchar(256) DEFAULT NULL,
  `Name` varchar(32) NOT NULL,
  `PhoneNumber` varchar(16) NOT NULL,
  `DateOfBirth` date DEFAULT NULL,
  `CreateDate` datetime NOT NULL,
  `UpdateDate` datetime NOT NULL,
  `DeleteFg` tinyint(1) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- ダンプしたテーブルのインデックス
--

--
-- テーブルのインデックス `mst_user`
--
ALTER TABLE `mst_user`
  ADD PRIMARY KEY (`UserId`),
  ADD KEY `EmailAddress` (`EmailAddress`,`DeleteFg`);

--
-- ダンプしたテーブルの AUTO_INCREMENT
--

--
-- テーブルの AUTO_INCREMENT `mst_user`
--
ALTER TABLE `mst_user`
  MODIFY `UserId` bigint(20) NOT NULL AUTO_INCREMENT;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
