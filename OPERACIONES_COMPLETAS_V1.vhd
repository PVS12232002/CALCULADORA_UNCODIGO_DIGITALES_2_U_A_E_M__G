library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity OPERACIONES_COMPLETAS_V1 is
    Port (
        N0, N1, N2, N3, N4, N5, N6, N7 : in STD_LOGIC;
        M0, M1, M2, M3, M4, M5, M6, M7 : in STD_LOGIC;
        OP : in STD_LOGIC_VECTOR(1 downto 0);
        salida_unidades : out STD_LOGIC_VECTOR(6 downto 0);
        salida_decenas : out STD_LOGIC_VECTOR(6 downto 0);
        salida_centenas : out STD_LOGIC_VECTOR(6 downto 0);
        salida_unidad_millar : out STD_LOGIC_VECTOR(6 downto 0);
        salida_decena_millar : out STD_LOGIC_VECTOR(6 downto 0);
        salida_centena_millar : out STD_LOGIC_VECTOR(6 downto 0);
        salida_unidad_millon : out STD_LOGIC_VECTOR(6 downto 0);
		  punto : out STD_LOGIC;
        signo : out STD_LOGIC
		  --resultado_bin1 : out signed(23 downto 0)
    );
end OPERACIONES_COMPLETAS_V1;

architecture Behavioral of OPERACIONES_COMPLETAS_V1 is
    -- Señales internas
    signal N_bin1, M_bin1 : STD_LOGIC_VECTOR(7 downto 0);
	 signal error : STD_LOGIC;
	 signal N_bin, M_bin : signed(7 downto 0);
    signal resultado_bin : SIGNED(23 downto 0);
    signal unidades, decenas, centenas, unidad_millar, decena_millar, centena_millar, unidad_millon : STD_LOGIC_VECTOR(3 downto 0);
begin
    -- Instancia de ENTRADA
    ENTRADAS: process(N0, N1, N2, N3, N4, N5, N6, N7, M0, M1, M2, M3, M4, M5, M6, M7)
    begin
        N_bin1 <= N7 & N6 & N5 & N4 & N3 & N2 & N1 & N0;  -- Concatenación para A
        M_bin1 <= M7 & M6 & M5 & M4 & M3 & M2 & M1 & M0;  -- Concatenación para B
		  N_Bin<= signed(N_bin1);
		  M_Bin<= signed(M_bin1);
    end process;

    -- Operaciones
OPERACIONES: process(OP, N_bin, M_bin)
    variable tempN2 : SIGNED(15 downto 0);
    variable tempN1 : SIGNED(23 downto 0);
	 variable tempN3 : SIGNED(23 downto 0);
	 variable tempResultado : SIGNED(23 downto 0);
begin
    

    case OP is
        when "00" => -- Suma
		  error <= '0';  -- Señal de error activa
				tempResultado := resize(N_bin, 24) + resize(M_bin, 24);
        when "01" => -- Resta
		  error <= '0';  -- Señal de error activa
            tempResultado := resize(N_bin, 24) - resize(M_bin, 24);
        when "10" => -- Multiplicación
		  error <= '0';  -- Señal de error activa
		      tempN2 := resize(N_bin, 8) * resize(M_bin, 8);
            tempResultado := resize(tempN2, 24);
        when "11" => -- División
            if N_bin = 0 then
				error <= '0';  -- Señal de error activa
            tempResultado := (others => '0');  -- Resultado es 0
				-- Caso donde B es 0
					elsif M_bin = 0 then
						error <= '1';  -- Señal de error activa
						tempResultado := (others => '0');  -- Resultado es 0
				else
				error <= '0';  -- Señal de error activa
						-- Realiza la multiplicación por 10000 y la división
					
					tempN3 := resize((resize(N_bin, 16) * 10000) / resize(M_bin, 16), 24);  -- Realiza la división y escala a 24 bits
					tempResultado := resize(tempN3, 24);
        end if;
    end case;
		case OP is
        when "00" => -- Suma
		  punto <= '0';  
        when "01" => -- Resta
		  punto <= '0';
        when "10" => -- Multiplicación
		  punto <= '0';  
        when "11" => -- División
        punto <= '1';  
    end case;
    resultado_bin <= signed(tempResultado);
	 --resultado_bin1 <=resultado_bin;
end process;

    -- Instancia de CONVERTIDOR
    CONVERTIDOR: process(resultado_bin)
        variable temp : unsigned(23 downto 0);
        variable bcd_temp : unsigned(27 downto 0);
    begin
        if resultado_bin(23) = '1' then
            signo <= '0';
            temp := unsigned(not resultado_bin) + 1; -- Complemento a 2
        else
            signo <= '1';
            temp := unsigned(resultado_bin);
        end if;

        -- Algoritmo de doble dabble
        bcd_temp := (others => '0');  -- Initialize to zero
for i in 23 downto 0 loop
    if bcd_temp(3 downto 0) > 4 then
        bcd_temp(3 downto 0) := bcd_temp(3 downto 0) + 3;
    end if;
    if bcd_temp(7 downto 4) > 4 then
        bcd_temp(7 downto 4) := bcd_temp(7 downto 4) + 3;
    end if;
    if bcd_temp(11 downto 8) > 4 then
        bcd_temp(11 downto 8) := bcd_temp(11 downto 8) + 3;
    end if;
    if bcd_temp(15 downto 12) > 4 then
        bcd_temp(15 downto 12) := bcd_temp(15 downto 12) + 3;
    end if;
    if bcd_temp(19 downto 16) > 4 then
        bcd_temp(19 downto 16) := bcd_temp(19 downto 16) + 3;
    end if;

    bcd_temp := bcd_temp(26 downto 0) & temp(23);  -- Shift to maintain the full width
    temp := temp(22 downto 0) & '0';  -- Shift the temp variable
end loop;

        unidades <= std_logic_vector(bcd_temp(3 downto 0));
        decenas <= std_logic_vector(bcd_temp(7 downto 4));
        centenas <= std_logic_vector(bcd_temp(11 downto 8));
        unidad_millar <= std_logic_vector(bcd_temp(15 downto 12));
        decena_millar <= std_logic_vector(bcd_temp(19 downto 16));
        centena_millar <= std_logic_vector(bcd_temp(23 downto 20));
        unidad_millon <= std_logic_vector(bcd_temp(27 downto 24)); -- Ajustado a la longitud correcta

    end process;

    -- Asignaciones a las salidas de 7 segmentos
    process(unidades, decenas, centenas, unidad_millar, decena_millar, centena_millar, unidad_millon)
    begin
        -- Salida de unidades
        case unidades is
            when "0000" => salida_unidades <= "1000000";  -- 0
            when "0001" => salida_unidades <= "1111001";  -- 1
            when "0010" => salida_unidades <= "0100100";  -- 2
            when "0011" => salida_unidades <= "0110000";  -- 3
            when "0100" => salida_unidades <= "0011001";  -- 4
            when "0101" => salida_unidades <= "0010010";  -- 5
            when "0110" => salida_unidades <= "0000010";  -- 6
            when "0111" => salida_unidades <= "1111000";  -- 7
            when "1000" => salida_unidades <= "0000000";  -- 8
            when "1001" => salida_unidades <= "0010000";  -- 9
            when others => salida_unidades <= "1111111";  -- Error
        end case;

        -- Salida de decenas
        case decenas is
            when "0000" => salida_decenas <= "1000000";  -- 0
            when "0001" => salida_decenas <= "1111001";  -- 1
            when "0010" => salida_decenas <= "0100100";  -- 2
            when "0011" => salida_decenas <= "0110000";  -- 3
            when "0100" => salida_decenas <= "0011001";  -- 4
            when "0101" => salida_decenas <= "0010010";  -- 5
            when "0110" => salida_decenas <= "0000010";  -- 6
            when "0111" => salida_decenas <= "1111000";  -- 7
            when "1000" => salida_decenas <= "0000000";  -- 8
            when "1001" => salida_decenas <= "0010000";  -- 9
            when others => salida_decenas <= "1111111";  -- Error
        end case;

        -- Salida de centenas
        case centenas is
            when "0000" => salida_centenas <= "1000000";  -- 0
            when "0001" => salida_centenas <= "1111001";  -- 1
            when "0010" => salida_centenas <= "0100100";  -- 2
            when "0011" => salida_centenas <= "0110000";  -- 3
            when "0100" => salida_centenas <= "0011001";  -- 4
            when "0101" => salida_centenas <= "0010010";  -- 5
            when "0110" => salida_centenas <= "0000010";  -- 6
            when "0111" => salida_centenas <= "1111000";  -- 7
            when "1000" => salida_centenas <= "0000000";  -- 8
            when "1001" => salida_centenas <= "0010000";  -- 9
            when others => salida_centenas <= "1111111";  -- Error
        end case;

        -- Salida de unidad_millar
        case unidad_millar is
            when "0000" => salida_unidad_millar <= "1000000";  -- 0
            when "0001" => salida_unidad_millar <= "1111001";  -- 1
            when "0010" => salida_unidad_millar <= "0100100";  -- 2
            when "0011" => salida_unidad_millar <= "0110000";  -- 3
            when "0100" => salida_unidad_millar <= "0011001";  -- 4
            when "0101" => salida_unidad_millar <= "0010010";  -- 5
            when "0110" => salida_unidad_millar <= "0000010";  -- 6
            when "0111" => salida_unidad_millar <= "1111000";  -- 7
            when "1000" => salida_unidad_millar <= "0000000";  -- 8
            when "1001" => salida_unidad_millar <= "0010000";  -- 9
            when others => salida_unidad_millar <= "1111111";  -- Error
        end case;

        -- Salida de decena_millar
        case decena_millar is
            when "0000" => salida_decena_millar <= "1000000";  -- 0
            when "0001" => salida_decena_millar <= "1111001";  -- 1
            when "0010" => salida_decena_millar <= "0100100";  -- 2
            when "0011" => salida_decena_millar <= "0110000";  -- 3
            when "0100" => salida_decena_millar <= "0110011";  -- 4
            when "0101" => salida_decena_millar <= "0010010";  -- 5
            when "0110" => salida_decena_millar <= "0000010";  -- 6
            when "0111" => salida_decena_millar <= "1111000";  -- 7
            when "1000" => salida_decena_millar <= "0000000";  -- 8
            when "1001" => salida_decena_millar <= "0010000";  -- 9
            when others => salida_decena_millar <= "1111111";  -- Error
        end case;

        -- Salida de centena_millar
        case centena_millar is
            when "0000" => salida_centena_millar <= "1000000";  -- 0
            when "0001" => salida_centena_millar <= "1111001";  -- 1
            when "0010" => salida_centena_millar <= "0100100";  -- 2
            when "0011" => salida_centena_millar <= "0110000";  -- 3
            when "0100" => salida_centena_millar <= "0011001";  -- 4
            when "0101" => salida_centena_millar <= "0010010";  -- 5
            when "0110" => salida_centena_millar <= "0000010";  -- 6
            when "0111" => salida_centena_millar <= "1111000";  -- 7
            when "1000" => salida_centena_millar <= "0000000";  -- 8
            when "1001" => salida_centena_millar <= "0010000";  -- 9
            when others => salida_centena_millar <= "1111111";  -- Error
        end case;

        -- Salida de unidad_millon
        case unidad_millon is
            when "0000" => salida_unidad_millon <= "1000000";  -- 0
            when "0001" => salida_unidad_millon <= "1111001";  -- 1
            when "0010" => salida_unidad_millon <= "0100100";  -- 2
            when "0011" => salida_unidad_millon <= "0110000";  -- 3
            when "0100" => salida_unidad_millon <= "0011001";  -- 4
            when "0101" => salida_unidad_millon <= "0010010";  -- 5
            when "0110" => salida_unidad_millon <= "0000010";  -- 6
            when "0111" => salida_unidad_millon <= "1111000";  -- 7
            when "1000" => salida_unidad_millon <= "0000000";  -- 8
            when "1001" => salida_unidad_millon <= "0010000";  -- 9
            when others => salida_unidad_millon <= "1111111";  -- Error
        end case;
			if error ='1' then
				salida_unidades <= "1001110";
				salida_decenas <= "1000000";
				salida_centenas <= "1001110";
				salida_unidad_millar <= "1001110";
				salida_decena_millar <= "0000100";
            salida_centena_millar <= "1111111";
				salida_unidad_millon <= "1111111";
        end if;
    end process;
end Behavioral;