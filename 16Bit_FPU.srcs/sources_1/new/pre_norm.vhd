library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity pre_norm is
    Port (
        oper1_in    : in  STD_LOGIC_VECTOR(15 downto 0);
        oper2_in    : in  STD_LOGIC_VECTOR(15 downto 0);
        clk         : in  STD_LOGIC;
        add         : in  STD_LOGIC;
        outExpo     : out STD_LOGIC_VECTOR(5 downto 0);
        outSign     : out STD_LOGIC;
        outMantBig  : out STD_LOGIC_VECTOR(39 downto 0);
        outMantSmall: out STD_LOGIC_VECTOR(39 downto 0)
    );
end pre_norm;

architecture Behavioral of pre_norm is
    signal aSign, bSign        : STD_LOGIC;
    signal aExpo, bExpo        : UNSIGNED(5 downto 0);
    signal aMant, bMant        : UNSIGNED(9 downto 0);
    signal gExpo, lExpo        : UNSIGNED(5 downto 0);
    signal diffExpo, diff      : UNSIGNED(5 downto 0);
    signal op_dn               : STD_LOGIC;
    signal lMant, gMant        : UNSIGNED(9 downto 0);
    signal tempShft, postShft  : STD_LOGIC_VECTOR(39 downto 0);
    signal shftAmnt            : UNSIGNED(5 downto 0);
    signal sticky              : STD_LOGIC;
    signal finalSm, finalBi    : STD_LOGIC_VECTOR(39 downto 0);
    signal sign                : STD_LOGIC_VECTOR(2 downto 0);
    signal i                   : INTEGER range 0 to 63;
begin
    -- Extract sign, exponent, and mantissa from inputs
    aSign <= oper1_in(15);
    bSign <= oper2_in(15);
    aExpo <= UNSIGNED(oper1_in(14 downto 10));
    bExpo <= UNSIGNED(oper2_in(14 downto 10));
    aMant <= UNSIGNED(oper1_in(9 downto 0));
    bMant <= UNSIGNED(oper2_in(9 downto 0));

    -- Calculate greater and lesser exponents and their difference
    gExpo    <= aExpo when aExpo > bExpo else bExpo;
    lExpo    <= bExpo when aExpo > bExpo else aExpo;
    diffExpo <= gExpo - lExpo;
    diff     <= diffExpo when ((aExpo = 0) xor (bExpo = 0)) else diffExpo - 1;

    -- Determine if denormal number is present
    op_dn <= '1' when lExpo /= 0 else '0';

    -- Get smaller and larger mantissas
    lMant <= bMant when aExpo > bExpo else aMant;
    gMant <= aMant when aExpo > bExpo else bMant;

    -- Create temporary shifted mantissa
    tempShft <= op_dn & STD_LOGIC_VECTOR(lMant) & (28 downto 0 => '0');

    -- Determine shift amount
    shftAmnt <= (others => '1') when diff > 40 else diff;

    -- Shift to align mantissas
    postShft <= std_logic_vector(shift_right(unsigned(tempShft), to_integer(shftAmnt)));

    -- Calculate sticky bit
    process(all)
    begin
        sticky <= '0';
        for i in 0 to to_integer(shftAmnt - 1) loop
            if tempShft(i) = '1' then
                sticky <= '1';
            end if;
        end loop;
    end process;

    -- Form the final smaller mantissa with sticky bit
    finalSm <= postShft(39 downto 1) & (postShft(0) or sticky);

    -- Form the final larger mantissa
    finalBi <= op_dn & STD_LOGIC_VECTOR(gMant) & (28 downto 0 => '0');

    -- Determine output sign
    sign <= aSign & bSign & add;

    process(sign, aMant, bMant)
    begin
        case sign is
            when "001" =>
                outSign <= '0';
            when "011" =>
                if bMant > aMant then
                    outSign <= '1';
                else
                    outSign <= '0';
                end if;
            when "101" =>
                if bMant > aMant then
                    outSign <= '0';
                else
                    outSign <= '1';
                end if;
            when "111" =>
                outSign <= '1';
            when others =>
                outSign <= '0';
        end case;
    end process;

    -- Update outputs on clock edge
    process(clk)
    begin
        if rising_edge(clk) then
            outMantSmall <= finalSm;
            outMantBig   <= finalBi;
            if (aExpo = bExpo) and (aMant = bMant) and (op_dn = '1') then
                outExpo <= (others => '0');
                outExpo(0) <= '1';
            else
                outExpo <= STD_LOGIC_VECTOR(gExpo);
            end if;
        end if;
    end process;
end Behavioral;
