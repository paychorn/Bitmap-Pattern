-------------------------------------------------------------------------------------------------------
-- Copyright (c) 2017, Design Gateway Co., Ltd.
-- All rights reserved.
--
-- Redistribution and use in source and binary forms, with or without modification,
-- are permitted provided that the following conditions are met:
-- 1. Redistributions of source code must retain the above copyright notice,
-- this list of conditions and the following disclaimer.
--
-- 2. Redistributions in binary form must reproduce the above copyright notice,
-- this list of conditions and the following disclaimer in the documentation
-- and/or other materials provided with the distribution.
--
-- 3. Neither the name of the copyright holder nor the names of its contributors
-- may be used to endorse or promote products derived from this software
-- without specific prior written permission.
--
-- THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
-- ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
-- THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
-- IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
-- INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
-- PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
-- HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
-- OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE,
-- EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
-------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------
----------------------------------------------------------------------------------
-- Filename     HDMI.vhd
-- Title        Top
--
-- Company      Design Gateway Co., Ltd.
-- Project      DDCamp HDMI-IP
-- PJ No.       
-- Syntax       VHDL
-- Note         
-- Version      1.00
-- Author       B.Attapon
-- Date         2017/11/17
-- Remark       New Creation
----------------------------------------------------------------------------------
----------------------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.STD_LOGIC_ARITH.all;
use IEEE.STD_LOGIC_UNSIGNED.all;

entity HDMI is
	port (
		RstB         : in    std_logic; -- use push button Key0 (active low)
		Clk          : in    std_logic; -- clock input 100 MHz

		-- User Control Interface
		HDMIReq      : in    std_logic; -- request to start HDMI Module
		HDMIBusy     : out   std_logic; -- HDMI Module is busy
		HDMIStatus   : out   std_logic_vector(1 downto 0);
                    -- [1] Error Flag when FIFOEmpty = '1' along with sending picture
										-- [0] Busy Flag for HDMI I2C Configuration
		HDMIUserClk  : out   std_logic; -- User Clock for HDMI

		-- User Data Interface
		HDMIFfRdEn   : out   std_logic; -- Read HDMI Enable for FIFO
		HDMIFfRdData : in    std_logic_vector(23 downto 0); --	Read FIFO Data for HDMI
		HDMIFfEmpty  : in    std_logic; -- FIFO Empty Flag for HDMI
		HDMIFfRdCnt  : in    std_logic_vector(15 downto 0); -- Read FIFO Counter for HDMI

		-- HDMI Control Interface
		HDMI_TX_INT  : in    std_logic; -- HDMI Interrupt
		HDMI_I2C_SCL : out   std_logic; -- I2C Clock
		HDMI_I2C_SDA : inout std_logic; -- I2C Data

		-- HDMI Data Interface
		HDMI_TX_CLK  : out   std_logic; -- HDMI Clock
		HDMI_TX_D    : out   std_logic_vector(23 downto 0); -- HDMI Data
		HDMI_TX_DE   : out   std_logic; -- HDMI Data Enable
		HDMI_TX_HS   : out   std_logic; -- HDMI HSync
		HDMI_TX_VS   : out   std_logic  -- HDMI VSync
	);
end entity;

architecture rtl of HDMI is

  -------------------------------------------------------------------------
  -- Component Declaration
  -------------------------------------------------------------------------
  component HDMIConfig is
    port (
      Clk         : in    std_logic;
      RstB        : in    std_logic;

      -- I2C Interface
      I2CSDA      : inout std_logic;
      I2CSCL      : out   std_logic;

      -- HDMI Interface
      HDMI_TX_INT : in    std_logic;

      Busy        : out   std_logic
    );
  end component;

  component VGAGenerator is
    port (
      Clk         : in  std_logic;
      RstB        : in  std_logic;

      -- User Output interface
      VGAReq      : in  std_logic;
      VGABusy     : out std_logic;
      VGAError    : out std_logic;

      VGAFfRdEn   : out std_logic;
      VGAFfRdData : in  std_logic_vector(23 downto 0);
      VGAFfEmpty  : in  std_logic;
      VGAFfRdCnt  : in  std_logic_vector(15 downto 0); -- not use

      -- VGA Output Interface
      VGAClk      : out std_logic;
      VGAClkB     : out std_logic;
      VGADe       : out std_logic;
      VGAHSync    : out std_logic;
      VGAVSync    : out std_logic;
      VGAData     : out std_logic_vector(23 downto 0)
    );
  end component;

  ----------------------------------------------------------------------------------
  -- Signal declaration
  ----------------------------------------------------------------------------------
  signal VGAError     : std_logic; -- Error Flag when FIFOEmpty = '1' along with sending picture
  signal HDMIConfBusy : std_logic; -- Busy Flag for HDMI I2C Configuration

begin

  ----------------------------------------------------------------------------------
  -- Output assignment
  ----------------------------------------------------------------------------------
  HDMIStatus(1) <= VGAError;
  HDMIStatus(0) <= HDMIConfBusy;

  ----------------------------------------------------------------------------------
  -- DFF 
  ----------------------------------------------------------------------------------
  u_HDMIConfig: HDMIConfig
    port map (
      Clk         => Clk,
      RstB        => RstB,

      I2CSDA      => HDMI_I2C_SDA,
      I2CSCL      => HDMI_I2C_SCL,

      HDMI_TX_INT => HDMI_TX_INT,

      Busy        => HDMIConfBusy
    );

  u_VGAGenerator: VGAGenerator
    port map (
      Clk         => Clk,
      RstB        => RstB,

      VGAReq      => HDMIReq,
      VGABusy     => HDMIBusy,
      VGAError    => VGAError,

      VGAFfRdEn   => HDMIFfRdEn,
      VGAFfRdData => HDMIFfRdData,
      VGAFfEmpty  => HDMIFfEmpty,
      VGAFfRdCnt  => HDMIFfRdCnt,

      VGAClk      => HDMIUserClk,
      VGAClkB     => HDMI_TX_CLK,
      VGADe       => HDMI_TX_DE,
      VGAHSync    => HDMI_TX_HS,
      VGAVSync    => HDMI_TX_VS,
      VGAData     => HDMI_TX_D
    );

end architecture;
