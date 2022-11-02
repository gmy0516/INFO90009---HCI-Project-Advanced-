%  [s, r]=system('ipconfig')
%                  % r=regexp(r,'IP Address. . . . . . . . . . . . : \d{1,3}.\d{1,3}.\d{1,3}.\d{1,3}','match')
%                  r=regexp(r,'IPv4 . . . . . . . . . . . . : \d{1,3}.\d{1,3}.\d{1,3}.\d{1,3}','match');
%                   r=r{1}
%                   r=regexp(r,'\d{1,3}.\d{1,3}.\d{1,3}.\d{1,3}','match')
%                   li                                                                                                                                                                                      ···                                                                                                                                                                                     p=r{1}
%                   disp(['IP：',lip])

clear;
arduino = serialport("COM8",115200);

pause(0.5);
t_client = tcpclient('10.13.194.170',81,"Timeout",120);

pause(0.1);

fopen(t_client); % server player : red


% Create Board
[y,x] = meshgrid(1:8);
chess_board= arrayfun(@(x,y)[x,y],x,y,'UniformOutput',false);

% Start points
starting_red = [1,1];
starting_blue = [8,8];

% choose a chessboard layout
chess_board_layout_index = randi([1 3]);

while (1)
    chess_board_layout_index = read(t_client);
    if(~isempty(chess_board_layout_index))
        break;
    end
end

% Select random campsites - Strategy 2: Fixed positions
chess_board_layout = {{}};
chess_board_layout{1} = {[1,8], [2,3], [3,6], [5,4], [6,6], [8,1], [8,4]};
chess_board_layout{2} = {[2,6], [3,3], [4,1], [4,5], [5,7], [6,3], [8,5]};
chess_board_layout{3} = {[1,7], [2,4], [3,6], [5,2], [5,5], [5,8], [7,3]};

% Step 1 - Calculating locations around a campsite
locations_around_camp = {{}};
locations_around_camp_incluede_camp = {{}};
k = 1;
k_2 = 1;
for num_camp = 1:length(chess_board_layout{chess_board_layout_index})
    for i = -1:1
        for j = -1:1
            if ((i == 0) && (j == 0)) || (chess_board_layout{chess_board_layout_index}{num_camp}(1) + i > 8) || (chess_board_layout{chess_board_layout_index}{num_camp}(1) + i < 1) || (chess_board_layout{chess_board_layout_index}{num_camp}(2) + j > 8) || (chess_board_layout{chess_board_layout_index}{num_camp}(2) + j < 1)
           
            else
            locations_around_camp{num_camp}{k} = [chess_board_layout{chess_board_layout_index}{num_camp}(1) + i, chess_board_layout{chess_board_layout_index}{num_camp}(2) + j];
            
            locations_around_camp_incluede_camp{num_camp}{k_2} = [chess_board_layout{chess_board_layout_index}{num_camp}(1) + i, chess_board_layout{chess_board_layout_index}{num_camp}(2) + j];
            k_2 = k_2 + 1;
            
            k = k + 1;
            end
        end
    end
    locations_around_camp_incluede_camp{num_camp}{k_2} = [chess_board_layout{chess_board_layout_index}{num_camp}(1),chess_board_layout{chess_board_layout_index}{num_camp}(2)];
    k = 1;
    k_2 = 1;
end

%%% [1]:untaken_camp_light，[2]: red_camp_light,[3]:blue_camp_light,[4]:invading_light, [5]:aimming_light, [6]: shooting_exposed_light 
%%% [9]:invading_light_dim, [10]: yourturn,[11]: enemyturn,[12]: blue_win，[13]: red_win


% Initialize
player_red_location = starting_red;
player_blue_location = starting_blue;
blue_aim_position = player_blue_location;
player_red_campsites = {{}};
player_blue_campsites = {{}};
player_red_campsites_amount = 0;
player_blue_campsites_amount = 0;

occupying_camp_red = false;
occupying_camp_blue = false;
camp_indicator_red = 0;
camp_indicator_blue = 0;
red_last_step = [0,0];
blue_last_step = [0,0];
blue_shoot_position = blue_aim_position;
red_shoot_position = [0,0];

enter_camp_index = {};
red_enter_camp = false;
red_leave_camp = false;

blue_enter_camp = false;
blue_leave_camp = false;

light_send_to_arduino = {};
your_turn = false;
you_win = false;
you_lose = false;

enemy_action = -1;

% initial light[chess
objective_campsites = "1,";
objective_campsites = objective_campsites  + to_str(location_to_arduino_array(chess_board_layout{chess_board_layout_index}));
write(arduino,objective_campsites,"string");
pause(0.2);

% cell_test = {{}};
% cell_test{end+1} = [1,1];
% cell_test(1) = [];
% Moving function - Test
while (1)
% Detect movement - red player
%%while (~isequal(player_red_location,fix_1{1}))
if(your_turn)

% 0 = move, 1 = shoot.
% detect the impact of enemy movement first, then get input from player
% Verify everything

 % Detect whehter in campsite and send the data to arduino - Detect
    
    % whether a player is occupying a campsite
    
    write(arduino,"11,","string");
    pause(0.2);
    if (occupying_camp_red) %
        player_red_campsites{end+1} = chess_board_layout{chess_board_layout_index}{camp_indicator_red};
       
        for i = 1:length(player_blue_campsites)
            if(isequal(red_last_step,player_blue_campsites{i}))
                
                player_blue_campsites(i) = [];
                break;
            end
        end

        red_campsite_arduino = "2," + to_str(location_to_arduino(chess_board_layout{chess_board_layout_index}{camp_indicator_red}));
        % Blue: locations_around_camp_four_directions
        %fprintf("[%d, %d] is under your control! You have %d campsites!\n",player_red_campsites{length(player_red_campsites)}(1),player_red_campsites{length(player_red_campsites)}(2), length(player_red_campsites)-1);
        %fprintf("blue have: %d...\n", length(player_blue_campsites));
        occupying_camp_red = false;
        write(arduino,red_campsite_arduino,"string");
        pause(0.5);
    end

    if (occupying_camp_blue) % 
        player_blue_campsites{end+1} = chess_board_layout{chess_board_layout_index}{camp_indicator_blue};
       
        for i = 1:length(player_red_campsites)
            if(isequal(blue_last_step,player_red_campsites{i}))
                
                player_red_campsites(i) = [];
                break;
            end
        end
        
        blue_campsite_arduino = "3," + to_str(location_to_arduino(chess_board_layout{chess_board_layout_index}{camp_indicator_blue}));

        % Blue: locations_around_camp_four_directions
        %fprintf("[%d, %d] is under your control! You have %d campsites!\n",player_red_campsites{length(player_red_campsites)}(1),player_red_campsites{length(player_red_campsites)}(2), length(player_red_campsites)-1);
        %fprintf("blue have: %d...\n", length(player_blue_campsites)-1);
        occupying_camp_blue = false;
        write(arduino,blue_campsite_arduino,"string");
        pause(0.5);
    end
    
        for i=1:length(chess_board_layout{chess_board_layout_index})
            
            if(isequal(player_red_location, chess_board_layout{chess_board_layout_index}{i}))
                for j = 1:length(player_red_campsites)
                    if (isequal(player_red_campsites{j},player_red_location))
                        break;
                    end
                    if (j == length(player_red_campsites))
                        occupying_camp_red = true;
                        red_last_step = player_red_location;
                        camp_indicator_red = i;
                    end
                end
           
                break;
              
            end
        end
        % whether entering enemy's campsites
        for i=1:length(locations_around_camp_incluede_camp)
            for j=1:length(locations_around_camp_incluede_camp{i})
                if (isequal(player_red_location,locations_around_camp_incluede_camp{i}{j}))
                    enter_camp_index{end+1} = i;
                    
                    break;
                end
            end
        end
    
        for j=1:length(enter_camp_index)
            
                for i=1:length(player_blue_campsites)
                    if(isequal(chess_board_layout{chess_board_layout_index}{enter_camp_index{j}},player_blue_campsites{i}))
                       
                        
                        % lit up
                        %fprintf("you just entered an enemy's camp!\n");
                        for k=1:length(locations_around_camp{enter_camp_index{j}})
                            % send the data to arduino
                            light_send_to_arduino{end+1} = locations_around_camp{enter_camp_index{j}}{k};              
                        end
                        break;
                    end
                end
            
        end
        if(length(light_send_to_arduino)>=1)
        light_send_to_arduino_str = "4," + to_str(location_to_arduino_array(light_send_to_arduino));
        write(arduino,light_send_to_arduino_str,"string");
        pause(0.2);
        else
            write(arduino,"9,","string");
            pause(0.2);
        end

        
        
        enter_camp_index = {};
        light_send_to_arduino = {};
        
        % whether players are closeby - blue
    if (enemy_action == 0)
        [x,Fs] = audioread('foot_step.wav');
        distance = [player_blue_location(1) - player_red_location(1), player_blue_location(2) - player_red_location(2)];
        if (abs(distance(1)) > 1 && abs(distance(1)) <= 2 && abs(distance(2)) <= 2) || (abs(distance(2)) > 1 && abs(distance(2)) <= 2 && abs(distance(1)) <= 2)
            if (distance(2) == 0)
                x(:,1) = 0.375 * x(:,1);
                x(:,2) = 0.375 * x(:,2);
            elseif (distance(2) > 1)
                    x(:,1) = 0.5 * x(:,1);
                    x(:,2) = 0.1 * x(:,2);
            elseif(distance(2) < -1)
                    x(:,1) = 0.1 * x(:,1);
                    x(:,2) = 0.5 * x(:,2);
            end
           sound(x,Fs);
        elseif (abs(distance(1)) <= 1 && abs(distance(2)) <= 1)
            if (distance(2) == 0)
                x(:,1) = 0.75 * x(:,1);
                x(:,2) = 0.75 * x(:,2);
            elseif (distance(2) > 0)
                x(:,2) = 0.2 * x(:,2);
            elseif (distance(2) < 0)
                x(:,1) = 0.2 * x(:,1);
            end
            sound(x,Fs);
        end
    elseif (enemy_action == 1)
        if length(player_red_campsites) == 1
            [x,Fs] = audioread('gun_shot_0.wav');
        elseif length(player_red_campsites) == 2
            [x,Fs] = audioread('gun_shot_1_2.wav');
        elseif length(player_red_campsites) == 3
            [x,Fs] = audioread('gun_shot_1_2.wav');
            x(:,1) = 0.75 * x(:,1);
            x(:,2) = 0.75 * x(:,2);
        elseif length(player_red_campsites) == 4
            [x,Fs] = audioread('gun_silencer.wav');
        end
        sound(x,Fs);
        pause(0.3);
        if (isequal(red_shoot_position,player_blue_location))
            you_lose = true;
            [x,Fs] = audioread('injury_scream.wav');
            sound(x,Fs);
            write(arduino,"13,","string");
        else
            shoot_to_arduino = "6," + to_str(location_to_arduino_array(square_creation(player_red_location,length(player_red_campsites)-1)));
            write(arduino,shoot_to_arduino,"string");
            pause(0.2);
        end
    end
% 2. Get action
while(1)
    movement = arduino.read(1,"string");
    if(~isempty(movement))
        break;
    end
end
    if (isequal(movement,"L"))
        if (player_blue_location(1) > 1)
            player_blue_location(1) = player_blue_location(1) - 1;
        else
            fprintf("not valid input");
        end
    end
    if (isequal(movement,"T"))
        if (player_blue_location(1) < 8)
            player_blue_location(1) = player_blue_location(1) + 1;
        else
            fprintf("not valid input");
        end
    end
    if (isequal(movement,"B"))
        if (player_blue_location(2) > 1)
            player_blue_location(2) = player_blue_location(2) - 1;
        else
            fprintf("not valid input");
        end
    end
    if (isequal(movement,"R"))
        if (player_blue_location(2) < 8)
            player_blue_location(2) = player_blue_location(2) + 1;
        else
            fprintf("not valid input");
        end
    end
    
    data_send = [player_blue_location(1),player_blue_location(2),0];

    % Aim, shoot function
    if (isequal(movement,"A"))
        [x,Fs] = audioread('aimming.wav');
        sound(x,Fs);
        write(t_client,[-1,-1,-1],"double");
        pause(0.2);
        while (1)
            aim = arduino.read(1,"string");

            if (isequal(aim,"L"))
                if (blue_aim_position(1) > 1)
                        blue_aim_position(1) = blue_aim_position(1) - 1;
                    else
                        fprintf("not valid input");
                end
            end
            if (isequal(aim,"T"))
                if (blue_aim_position(1) < 8)
                    blue_aim_position(1) = blue_aim_position(1) + 1;
                else
                    fprintf("not valid input");
                end
            end
            if (isequal(aim,"B"))
                if (blue_aim_position(2) > 1)
                    blue_aim_position(2) = blue_aim_position(2) - 1;
                else
                    fprintf("not valid input");
                end
            end
            if (isequal(aim,"R"))
                if (blue_aim_position(2) < 8)
                    blue_aim_position(2) = blue_aim_position(2) + 1;
                else
                    fprintf("not valid input");
                end
            end
            if (isequal(aim,"S"))
                if (sqrt((blue_aim_position(1) - player_blue_location(1))^2 + ...
                        (blue_aim_position(2) - player_blue_location(2))^2) < 2)
                    %fprintf("%d, %d\n", red_aim_position(1), red_aim_position(2));

                    data_send = [blue_aim_position(1),blue_aim_position(2),1];

                    if length(player_blue_campsites) == 1
                        [x,Fs] = audioread('gun_shot_0.wav');
                    elseif length(player_blue_campsites) == 2
                        [x,Fs] = audioread('gun_shot_1_2.wav');
                    elseif length(player_blue_campsites) == 3
                        [x,Fs] = audioread('gun_shot_1_2.wav');
                        x(:,1) = 0.75 * x(:,1);
                        x(:,2) = 0.75 * x(:,2);
                    elseif length(player_blue_campsites) == 4
                        [x,Fs] = audioread('gun_silencer.wav');
                    end
                    sound(x,Fs);
                    pause(0.3);
                    if (isequal(blue_aim_position,player_red_location))
                        you_win = true;
                        [x,Fs] = audioread('injury_scream.wav');
                        sound(x,Fs);
                        write(arduino,"12,","string");
                    end

                    break;
                else 
                    fprintf("invalid shooting position!");
                end
            end
        end
    end    
    
    blue_aim_position = player_blue_location;
    fprintf("my position : [%d %d], aimming location : [%d %d], action : %d\n", player_blue_location(1), ...
        player_blue_location(2), data_send(1),data_send(2),data_send(3));
    
    

    for i=1:length(chess_board_layout{chess_board_layout_index})
        
        if(isequal(player_blue_location, chess_board_layout{chess_board_layout_index}{i}))
            for j = 1:length(player_blue_campsites)
                if (isequal(player_blue_campsites{j},player_blue_location))
                    break;
                end
                if (j == length(player_blue_campsites))
                    occupying_camp_blue = true;
                    blue_last_step = player_blue_location;
                    camp_indicator_blue = i;
                end
            end
       
            break;
            

%             player_red_campsites_amount = player_red_campsites_amount + 1;
%             player_red_campsites{player_red_campsites_amount} = chess_board_layout{chess_board_layout_index}{i};
%             fprintf("[%d, %d] is under your control! You have %d campsites!",player_red_campsites{player_red_campsites_amount}(1),player_red_campsites{player_red_campsites_amount}(2), player_red_campsites_amount);
        end
    end
    
    
    %write(arduino,data_send,"double");
    %pause(0.5);
    write(t_client,data_send,"double");
    pause(0.5);
    if(length(player_blue_campsites) == 5)
        you_win = true;
        write(arduino,"12,","string");
        pause(0.2);
    end
    if(length(player_red_campsites) == 5)
        you_lose = true;
        write(arduino,"13,","string");
        pause(0.2);
    end
    if(you_win || you_lose)
        break;
    end

    your_turn = false;
    write(arduino,"10,","string");
    pause(0.2)
    
    if(movement == "quit")
        break;
    end
else % if enemy's turn
    [x,Fs] = audioread('aimming.wav');
    while(1)
        enemy_data = read(t_client,3,"double");
           if (~isempty(enemy_data))
               if(enemy_data(1) ~= -1)
                   if(enemy_data(3) ~= 1)
                        player_red_location(1) = enemy_data(1);
                        player_red_location(2) = enemy_data(2);
                        enemy_action = enemy_data(3);
                   else
                       red_shoot_position(1) = enemy_data(1);
                       red_shoot_position(2) = enemy_data(2);
                       enemy_action = enemy_data(3);
                   end
                   your_turn = true;
                   break;
               else
                 sound(x,Fs);
                 
               end
           end
    end
end




% Step 2 - Sending data to database

% Step 2.5 - Receiving data from database

% Step 3 - lit up the light




% while (true)
%     pause(0.1)
%     if (t_server.Connected)
%         if (your_turn)
%             write(t_server,player_red_location,test);
%             your_turn = false;
%             
%             %fprintf("your_turn = false");
%         else
%             enemy_position = read(t_server,2,"double");
%             if (~isempty(enemy_position))
%                 %fprintf("enemy position:")
%                 your_turn = true;
%                 
%             end
%             i = i + 1;
%             fprintf("%d",i);
%         end
%     end
% end
%write(t_server,"hello world","string");




    
         
%write(t_server,"hello world","string");
 
% while (1)
%     if(t_server.Connected)
%         
%         write(t_server,"hello world","string");
%     end
% end

end

% searching for the IP address
% [s, r]=system('ipconfig')
%                 % r=regexp(r,'IP Address. . . . . . . . . . . . : \d{1,3}.\d{1,3}.\d{1,3}.\d{1,3}','match')
%                  r=regexp(r,'IPv4 . . . . . . . . . . . . : \d{1,3}.\d{1,3}.\d{1,3}.\d{1,3}','match');
%                  r=r{1}
%                  r=regexp(r,'\d{1,3}.\d{1,3}.\d{1,3}.\d{1,3}','match')
%                  lip=r{1}
%                  disp(['IP：',lip])

%%% get a single [x,y] to the location on the LED strip 
function bulb = location_to_arduino(x)
    if (mod(x(1),2) == 0)
        bulb = 8 * (8 - x(1)) + (8 - x(2));
    else 
        bulb = 8 * (8 - x(1)) + x(2) - 1;
    end
end

%%% get a list of [x,y] values to locations on the LED strip 
function array_bulb = location_to_arduino_array(x)
    temp_array = {};
    for i = 1:length(x)
        if (mod(x{i}(1),2) == 0)
            temp_array{end+1} = 8 * (8 - x{i}(1)) + (8 - x{i}(2));
        else 
            temp_array{end+1} = 8 * (8 - x{i}(1)) + x{i}(2) - 1;
        end
    end
    array_bulb = temp_array;
end

%%% change the number to char type
function str = to_str(x)
    temp_str = "";
    for i = 1:length(x)
        temp_str = temp_str + string(x(i));
        temp_str = temp_str + ",";
    end
    str = temp_str;
end

%%% get random squares when exposed
function square = square_creation(x,camp_num)
    temp_list = {};
    index = -1;
    temp_square = {};
    final_square = {x};
    if (x(1) > 1 && x(2) > 1)
        temp_list{end+1} = 1; % left top
    end
    if (x(1) > 1 && x(2) < 8)
        temp_list{end+1} = 2;  % right top
    end
    if (x(1) <8 && x(2) > 1)
        temp_list{end+1} = 3; % left bottom
    end
    if (x(1) < 8 && x(2) < 8)
        temp_list{end+1} = 4; % right bottom
    end
    while (index == -1)
        temp_index = randi([1 4]);
        for i = 1:length(temp_list)
            if (temp_list{i} == temp_index)
                index = temp_index;
                break;
            end
        end
    end
    
    if (index == 1)
        temp_square = {[x(1)-1,x(2)-1],[x(1),x(2)-1],[x(1)-1,x(2)]};
    elseif (index == 2)
        temp_square = {[x(1)-1,x(2)+1],[x(1),x(2)+1],[x(1)-1,x(2)]};
    elseif (index == 3)
        temp_square = {[x(1)+1,x(2)-1],[x(1),x(2)-1],[x(1)+1,x(2)]};
    elseif (index == 4)
        temp_square = {[x(1),x(2)+1],[x(1)+1,x(2)+1],[x(1)+1,x(2)]};
    end
    for i = 1:camp_num
        j = randi([1 length(temp_square)]);
        final_square{end+1} = temp_square{j};
        temp_square(j) = [];
    end
    square = final_square;
end