library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

entity tt_um_maze_game is
    port (
        ui_in   : in  std_logic_vector(7 downto 0);
        uo_out  : out std_logic_vector(7 downto 0);
        uio_in  : in  std_logic_vector(7 downto 0);
        uio_out : out std_logic_vector(7 downto 0);
        uio_oe  : out std_logic_vector(7 downto 0);
        ena     : in  std_logic;
        clk     : in  std_logic;
        rst_n   : in  std_logic
    );
end entity;

architecture rtl of tt_um_maze_game is

  -- GRID konstanter
  constant GRID_SIZE : integer := 8;
  constant CELL_SIZE : integer := 32;

  -- GRID position på skärmen ( för feltestning )
  constant GRID_X : integer := 192;
  constant GRID_Y : integer := 112;

  -- VGA signaler
  signal hpos              : unsigned(9 downto 0) := (others => '0');
  signal vpos              : unsigned(9 downto 0) := (others => '0');
  signal hsync, vsync, vis : std_logic;

  -- Player pos på griden
  signal xpos : integer range 0 to 7 := 4;
  signal ypos : integer range 0 to 7 := 4;

  -- Riktning
  signal direction : integer range 0 to 3 := 0;

  signal last_input : std_logic_vector(3 downto 0) := (others => '0');

  signal r, g, b : unsigned(1 downto 0);

  signal proximity_check : std_logic_vector(7 downto 0);

  type matrix is array (0 to 7, 0 to 7) of std_logic;

  constant maze : matrix := (
    0 => ('0', '1', '0', '0', '0', '1', '0', '0'),
    1 => ('0', '0', '0', '1', '0', '1', '1', '0'),
    2 => ('1', '1', '1', '0', '0', '0', '0', '0'),
    3 => ('1', '0', '1', '1', '1', '1', '0', '1'),
    4 => ('0', '0', '0', '0', '0', '0', '0', '0'),
    5 => ('0', '1', '1', '0', '1', '1', '1', '0'),
    6 => ('0', '1', '0', '0', '1', '0', '1', '0'),
    7 => ('0', '0', '1', '0', '1', '0', '0', '0')
  );

begin
  -- ── VGA pixel counter ────────────────────────────────────────────────────
  process (clk, rst_n) is
  begin
    if rst_n = '0' then
      hpos <= (others => '0');
      vpos <= (others => '0');

    elsif rising_edge(clk) then
      if hpos = 799 then
        hpos <= (others => '0');
        if vpos = 524 then
          vpos <= (others => '0');
        else
          vpos <= vpos + 1;
        end if;
      else
        hpos <= hpos + 1;
      end if;
    end if;
  end process;

  hsync <= '0' when hpos < 96 else '1';
  vsync <= '0' when vpos < 2 else '1';
  vis   <= '1' when hpos >= 144 and hpos < 784 and vpos >= 35 and vpos < 515 else '0';

  -- ── Player movement ───────────
  process (clk, rst_n) is
    variable next_x : integer range 0 to 7;
    variable next_y : integer range 0 to 7;
  begin

    if rst_n = '0' then
      xpos <= 4;
      ypos <= 4;
      direction <= 0;

    elsif rising_edge(clk) then
      next_x := xpos;
      next_y := ypos;

      if last_input(0) = '0' and last_input(1) = '0' and last_input(2) = '0' then
        if ui_in(0) = '1' then
          direction <= direction + 1;
        elsif ui_in(2) = '1' then
          direction <= direction - 1;
        end if;

        if ui_in(1) = '1' then
          case direction is
            when 0 =>
              if ypos > 0 then
                next_y := ypos - 1;
              end if;
            when 1 =>
              if xpos < 7 then
                next_x := xpos + 1;
              end if;
            when 2 =>
              if ypos < 7 then
                next_y := ypos + 1;
              end if;
            when 3 =>
              if xpos > 0 then
                next_x := xpos - 1;
              end if;
            when others =>
              null;
          end case;
        end if;

        if maze(next_x, next_y) = '0' then
            xpos <= next_x;
            ypos <= next_y;
        else
          xpos <= xpos;
          ypos <= ypos;
        end if;

      end if;

      last_input <= ui_in(3 downto 0);

    end if;
  end process;

  -- ── Pixel colour ─────────────────────────────────────────────────────────
  process (vis, hpos, vpos, xpos, ypos, ui_in) is
    variable px : unsigned(9 downto 0);
    variable py : unsigned(9 downto 0);

    variable light_xpos : integer;
    variable light_ypos : integer;

    variable on_ground : boolean;
    variable on_walls  : boolean;
    variable on_player : boolean;

    variable close_proximity : boolean;

  begin
    r <= "00";
    g <= "00";
    b <= "00";

    proximity_check <= "11111111";

    px := hpos - 144;
    py := vpos - 35;

    light_xpos := xpos;
    light_ypos := ypos;

    close_proximity := false;
    on_walls := false;

    for y in 7 downto 0 loop
      for x in 7 downto 0 loop
        if maze(x, y) = '1' then
          on_walls := on_walls or
            (px >= GRID_X + x * CELL_SIZE and
            px < GRID_X + (x + 1) * CELL_SIZE and
            py >= GRID_Y + y * CELL_SIZE and
            py < GRID_Y + (y + 1) * CELL_SIZE);

          case direction is
            when 0 =>
              light_ypos := ypos - 1;
            when 1 => 
              light_xpos := xpos + 1;
            when 2 =>
              light_ypos := ypos + 1;
            when 3 =>
              light_xpos := xpos - 1;
          end case;

          close_proximity := close_proximity or
            (px >= GRID_X + (light_xpos - 1) * CELL_SIZE and
            px < GRID_X + (light_xpos + 2) * CELL_SIZE and
            py >= GRID_Y + (light_ypos - 1) * CELL_SIZE and
            py < GRID_Y + (light_ypos + 2) * CELL_SIZE);
        end if;
      end loop;
    end loop;

    on_ground :=
      (px >= GRID_X and
      px < GRID_X + GRID_SIZE * CELL_SIZE and
      py >= GRID_Y and
      py < GRID_Y + GRID_SIZE * CELL_SIZE);

    on_player :=
      (px >= GRID_X + xpos * CELL_SIZE and
      px < GRID_X + (xpos + 1) * CELL_SIZE and
      py >= GRID_Y + ypos * CELL_SIZE and
      py < GRID_Y + (ypos + 1) * CELL_SIZE);

    if vis = '1' then

      if py >= 240 then
          r <= "01";
          g <= "01";
          b <= "01";
      end if;
      if py <= 240 then
          r <= "01";
          g <= "01";
          b <= "00";
      end if;

      -- 1 x x
      -- x x x
      -- x x x
      if proximity_check(0) = '1' then
        if py < 320 and py > 160 and px >= 0 and px <= 214 then
            r <= "10";
            g <= "10";
            b <= "01";
        end if;
      end if;

      -- x x 1
      -- x x x
      -- x x x
      if proximity_check(2) = '1' then
        if py < 320 and py > 160 and px >= 426 and px <= 640 then
            r <= "10";
            g <= "10";
            b <= "01";
        end if;
      end if;

      -- x 1 x
      -- x x x
      -- x x x
      if proximity_check(1) = '1' then
        if py < 320 and py > 160 and px >= 214 and px <= 426 then
            r <= "10";
            g <= "10";
            b <= "01";
        end if;
      end if;

      -- x x x
      -- 1 x x
      -- x x x
      if proximity_check(3) = '1' then
        if 640 * py < 480 * 640 - 480 * 107 and 640 * py > 480 * 107 and px >= 0 and px <= 107 then
            r <= "10";
            g <= "10";
            b <= "01";
        end if;
        if 640 * py > 480 * px and 640 * py < 480 * 640 - 480 * px then
          if px <= 214 and px >= 107 then
            r <= "10";
            g <= "10";
            b <= "00";
          end if;
        end if;
      end if;

      -- x x x
      -- x x 1
      -- x x x
      if proximity_check(5) = '1' then
        if 640 * py < 480 * 640 - 480 * 107 and 640 * py > 480 * 107 and px <= 640 and px >= 640 - 107 then
            r <= "10";
            g <= "10";
            b <= "01";
        end if;
        if 640 * py < 480 * px and 640 * py > 480 * 640 - 480 * px then
          if px >= 426 and px <= 426 + 107 then
            r <= "10";
            g <= "10";
            b <= "00";
          end if;
        end if;
      end if;

      -- x x x
      -- x 1 x
      -- x x x
      if proximity_check(4) = '1' then
        if 640 * py > 480 * 107 and 640 * py < 480 * 640 - 480 * 107 and px >= 107 and px <= 640 - 107 then
            r <= "10";
            g <= "10";
            b <= "01";
        end if;
      end if;

      -- x x x
      -- x x x
      -- 1 x x
      if proximity_check(6) = '1' then
        if 640 * py > 480 * px and 640 * py < 480 * 640 - 480 * px then
          if px <= 214 / 2 then
            r <= "10";
            g <= "10";
            b <= "00";
          end if;
        end if;
      end if;

      -- x x x
      -- x x x
      -- x x 1
      if proximity_check(7) = '1' then
        if 640 * py < 480 * px and 640 * py > 480 * 640 - 480 * px then
          if px >= 426 + 214 / 2 then
            r <= "10";
            g <= "10";
            b <= "00";
          end if;
        end if;
      end if;

    end if;
  end process;

  uo_out <= hsync & b(0) & g(0) & r(0) & vsync & b(1) & g(1) & r(1);
end architecture;
