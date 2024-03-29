% Erion Plaku
% Introduction to Robotics
% Department of Electrical Engineering and Computer Science
% Catholic University of America
%
% http://faculty.cua.edu/plaku/
%
% Copyright 2012 by Erion Plaku
% The content may be reproduced under the obligation to acknowledge the source
%
% Modified 2014 by Kenneth Marino
%
function [] = RunBug(fname, option)
% RunBug(fname, option)
%  - fname: name of obstacle file
%  - option 1: Bug1
%  - option 2: Bug2
%  - option 3: Potential Fields

    % Values to read from file
    domaintype = '';
    xcoordinates = [];
    ycoordinates = [];
    centerx = [];
    centery = [];
    radius = [];
    init = [];
    goal = [];
    xlimit = [];
    ylimit = [];
    
    % Read values from file
    fid = fopen(fname, 'r');
    cline = fgetl(fid);
    while ischar(cline)
        switch cline
            case 'domaintype'
                cline = fgetl(fid);
                domaintype = cline;
            case 'xcoordinates'
                cline = fgetl(fid);
                xcoordinates = str2num(cline);
            case 'ycoordinates'
                cline = fgetl(fid);
                ycoordinates = str2num(cline);
            case 'centerx'
                cline = fgetl(fid);
                centerx = str2num(cline);
            case 'centery'
                cline = fgetl(fid);
                centery = str2num(cline);
            case 'radius'
                cline = fgetl(fid);
                radius = str2num(cline);
            case 'init'
                cline = fgetl(fid);
                init = str2num(cline);
            case 'goal'
                cline = fgetl(fid);
                goal = str2num(cline);
            case 'xlimit'
                cline = fgetl(fid);
                xlimit = str2num(cline);
            case 'ylimit'
                cline = fgetl(fid);
                ylimit = str2num(cline);
        end     
       cline = fgetl(fid);
    end

    % Setup figure environment
    close all;
    clf;
    set(gca, 'xlim', xlimit); 
    set(gca, 'ylim', ylimit);
    grid on;
    hold on;   

    % Fill in obstacle polygons.
    if strcmp(domaintype, 'vertices')
        fill(xcoordinates, ycoordinates, 'b');
    elseif strcmp(domaintype, 'circles')
        for i = 1:length(centerx)
            x = centerx(i);
            y = centery(i);
            rad = radius(i);
            rectangle('Position',[x - rad, y - rad, rad*2, rad*2], ...
                'Curvature', [1,1], 'FaceColor','y');
        end
    end
    axis equal;
   
    % Set robot and goal center
    robotCenter = init;   
    plot(robotCenter(1), robotCenter(2), 'go', 'LineWidth', 6);
    goalCenter = goal;
    plot(goalCenter(1), goalCenter(2), 'ro', 'LineWidth', 6);

    % Set initial values
    prev = robotCenter;
    robotInit = robotCenter;
    
    % Set counter and other image save info
    counter = 0;
    dotlocation = find(fname == '.');
    savestr = 'RawImages/';
    if option == 1 || option == 2
        savestr = [savestr, 'Bug' num2str(option) '_' fname(1:dotlocation-1) '_fr_']; 
    else
        savestr = [savestr, 'PF_' fname(1:dotlocation-1) '_fr_']; 
    end
    
    % Keep track of movement
    totalmove = 0;

    % Set parameters
    params.whenToTurn  = 1.0;           % value to determine when to follow obstacle boundary
    params.step        = 1;             % step length that the robot can take
    params.mode        = 'Straight';    % operating mode for the robot -- initially, it should move straight 
    params.hit         = [0 0];         % store the hit point  
    params.leave       = [0 0];         % store the leave point
    params.distLeaveToGoal = inf;       % distance from leave point to goal    
    params.domaintype = domaintype;     % store domain type
    params.color = 'r';                 % draw color
    params.attrScale = 1;               % attractive scale factor
    params.repulScale = 500;           	% repulsive scale factor
    params.goalThresh = 20;             % goal threshold
    params.obsThresh = 25;              % obstacle threshold
    params.alpha = 0.1;                 % how much to move for potentials
    params.save = 0;                    % Whether or not to save to file
    
    % Save original image
    if (params.save)
        saveas(gcf, [savestr, sprintf('%05d', counter)], 'jpg');
    end
    
    while 1
        counter = counter + 1;
        
        if strcmp(domaintype, 'vertices')
            sensor = TakeSensorReading(domaintype, robotCenter, xcoordinates, ycoordinates);
        elseif strcmp(domaintype, 'circles')
            sensor = TakeSensorReading(domaintype, robotCenter, centerx, centery, radius);
        end
        
        % If Bug 1
        if option == 1
            if strcmp(domaintype, 'vertices')
                [move, params] = Bug1(robotInit, robotCenter, goalCenter, params, sensor, xcoordinates, ycoordinates);
            elseif strcmp(domaintype, 'circles')
                [move, params] = Bug1(robotInit, robotCenter, goalCenter, params, sensor, centerx, centery, radius);
            end
            
        % If Bug 2
        elseif option == 2
            if strcmp(domaintype, 'vertices')
                [move, params] = Bug2(robotInit, robotCenter, goalCenter, params, sensor, xcoordinates, ycoordinates);
            elseif strcmp(domaintype, 'circles')
                [move, params] = Bug2(robotInit, robotCenter, goalCenter, params, sensor, centerx, centery, radius);
            end
            
        % If Potential Fields
        else
            if strcmp(domaintype, 'vertices')
                [move, params] = PF(robotInit, robotCenter, goalCenter, params, sensor, xcoordinates, ycoordinates);
            elseif strcmp(domaintype, 'circles')
                [move, params] = PF(robotInit, robotCenter, goalCenter, params, sensor, centerx, centery, radius);
            end
        end
        
        % Update totalmove
        if ~strcmp(params.mode, 'Straight')
            totalmove = totalmove + norm(move);
        else
            totalmove = totalmove + params.step;
        end
       
        % Move the robot and update the GUI
        robotCenter = robotCenter + move;
        line([prev(1), robotCenter(1)], [prev(2), robotCenter(2)], ...
            'LineWidth', 2, 'Color', params.color);
        prev = robotCenter;
        if ArePointsNear(robotCenter, goalCenter, params.step)
            msgbox('Robot reached goal!', 'Done');
            disp(['Total distance: ' num2str(totalmove)]);
            return;
        end
        drawnow;
        
        % Save to file
        if (params.save)
            saveas(gcf, [savestr, sprintf('%05d', counter)], 'jpg');
        end
    end
end