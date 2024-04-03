library IEEE;
use IEEE.std_logic_1164.ALL;
use IEEE.STD_LOGIC_ARITH.all;
use IEEE.STD_LOGIC_UNSIGNED.all;

Entity UserWrDdr Is
	Port
	(
		RstB					: in	std_logic;	-- use push button Key0 (active low)
		Clk						: in	std_logic;	-- clock input 100 MHz

		-- WrCtrl I/F
		MemInitDone		: in	std_logic;
		MtDdrWrReq		: out	std_logic;
		MtDdrWrBusy		: in	std_logic;
		MtDdrWrAddr		: out	std_logic_vector( 28 downto 7 );
		
		-- T2UWrFf I/F
		T2UWrFfRdEn		: out	std_logic;
		T2UWrFfRdData	: in	std_logic_vector( 63 downto 0 );
		T2UWrFfRdCnt	: in	std_logic_vector( 15 downto 0 );
		
		-- UWr2DFf I/F
		UWr2DFfRdEn		: in	std_logic;
		UWr2DFfRdData	: out	std_logic_vector( 63 downto 0 );
		UWr2DFfRdCnt	: out	std_logic_vector( 15 downto 0 )
	);
End Entity UserWrDdr;

Architecture rtl Of UserWrDdr Is

----------------------------------------------------------------------------------
-- Component declaration
----------------------------------------------------------------------------------
	
----------------------------------------------------------------------------------
-- Signal declaration
----------------------------------------------------------------------------------

	-- WrCtrl I/F
	signal rMemInitDone	  : std_logic_vector( 1 downto 0 );   -- The memory initialization is complete 
	signal rMtDdrWrReq		: std_logic_vector( 1 downto 0 );   -- User request to write data to DDR
	signal rMtDdrWrAddr		: std_logic_vector( 28 downto 7 );  -- Start address to write data at DDR

Begin

----------------------------------------------------------------------------------
-- Output assignment
----------------------------------------------------------------------------------
	
	-- RdCtrl I/F
	MtDdrWrReq  	<= rMtDdrWrReq(0);
	MtDdrWrAddr	  <= rMtDdrWrAddr;

	-- Just bypass the data
	T2UWrFfRdEn 	<= UWr2DFfRdEn;
	UWr2DFfRdData <= T2UWrFfRdData;
	UWr2DFfRdCnt 	<= T2UWrFfRdCnt;

----------------------------------------------------------------------------------
-- DFF 
----------------------------------------------------------------------------------
  
	--[[ WrCtrl I/F ]] -----------------------------
  -- Synchronize the memory initialization done signal
	u_rMemInitDone : Process (Clk) Is
	Begin
		if ( rising_edge(Clk) ) then
			if ( RstB='0' ) then
				rMemInitDone	<= "00";
			else
				-- Use rMemInitDone(1) in your design
				rMemInitDone	<= rMemInitDone(0) & MemInitDone;
			end if;
		end if;
	End Process u_rMemInitDone;

	-- Synchornize the request and maintain last input
	u_rMtDdrWrReq : Process (Clk) is
  begin
		if ( rising_edge(Clk) ) then
			if ( RstB='0' ) then
				rMtDdrWrReq <= "00";
			else
				if ( MtDdrWrBusy = '0' ) then
					rMtDdrWrReq <= rMtDdrWrReq(0) & '1';
				else 
					rMtDdrWrReq <= rMtDdrWrReq(0) & '0';
				end if;
			end if;
		end if;
	end Process u_rMtDdrWrReq;

	-- Calculate the address from the dip switch
	u_rMtDdrWrAddr : Process (Clk) is
		begin
			if ( rising_edge(Clk) ) then
				if ( RstB='0' ) then
					-- first pixel (785408 to 785439): 785408/32
					rMtDdrWrAddr(28 downto 27) <= (others => '0');
					rMtDdrWrAddr(26 downto  7) <= conv_std_logic_vector(24544, 20);
				else
					if ( rMtDdrWrReq = "10" ) then
						-- auto change the ith image that we want to write
						-- last pixel (992 to 1023): 992/32
						if ( rMtDdrWrAddr(26 downto  7) = conv_std_logic_vector(31, 20)) then
							rMtDdrWrAddr(28 downto 27) <= rMtDdrWrAddr(28 downto 27) + 1;
							rMtDdrWrAddr(26 downto  7) <= conv_std_logic_vector(24544, 20);
						else
							if ( rMtDdrWrAddr(11 downto  7) = 31 ) then
								rMtDdrWrAddr(26 downto  7) <= rMtDdrWrAddr(26 downto 7) - 63;
							else
								rMtDdrWrAddr(26 downto  7) <= rMtDdrWrAddr(26 downto 7) + 1;
							end if;
						end if;
					else 
						rMtDdrWrAddr(28 downto 7) <= rMtDdrWrAddr(28 downto 7);
					end if;
				end if;
			end if;
		end Process u_rMtDdrWrAddr;

End Architecture rtl;