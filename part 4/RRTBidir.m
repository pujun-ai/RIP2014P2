function moves = RRTBidir(startNode, endNode, obstacles)
    t = cputime;
    obj = VideoWriter('BiDirTree');
    obj2 = VideoWriter('BiDirArm');
    open(obj);
    open(obj2);
   
    maxIter = 400;
    edgeMat = zeros(maxIter,maxIter);
    edgeMatG = zeros(maxIter,maxIter);
    goalFound = false;
    thresh = 1;
     armLengths = [2,2,1];
     figure;
     thetas = startNode';
     thetaTreeG = endNode;
     gNode1 =endNode;
     gNode2 = startNode;
     
     
     thetaTree = thetas';
     plot3(thetas(1), thetas(2), thetas(3), 'g.', 'MarkerSize', 20);
     
     hold on;
      plot3(endNode(1), endNode(2), endNode(3), 'm.', 'MarkerSize', 20);
    % plot(endNode(1), endNode(2), 'm.', 'MarkerSize', 20);
     %plot(endNode(1), endNode(2), 'm.', 'MarkerSize', 20);
     axis square
     axis equal
%      xlabel 'x-distance';
%      ylabel 'y-distance';
     %axis([-5,5,-5,5]);
     xlabel 'theta 1';
     ylabel 'theta 2';
     zlabel 'theta 3';
     view(3);
     axis([-pi,pi,-pi,pi, -pi, pi]);
     [row,~] = size(obstacles);
     circles = [];
        for r = 1:row
         obs = obstacles(r,:);
         corners = [-1.*obs(4), obs(4), obs(4), -1.*obs(4), -1.*obs(4);...
             -1.*obs(5), -1.*obs(5), obs(5), obs(5), -1.*obs(5)];
         rot = [cos(obs(3)), -1.*sin(obs(3)); sin(obs(3)), cos(obs(3))];
         corners = rot*corners;
         corners(1,:) = corners(1,:)./2 + obs(1);
         corners(2,:) = corners(2,:)./2 + obs(2);
       % plot(corners(1,:), corners(2,:), 'g-');
        circles = [circles; corners];
     end
   baseTheta = thetaTree(:, 1);
   baseThetaG = thetaTreeG(:,1);
   count = 0;
   numIter = 0;
   while numIter < maxIter-1 & ~goalFound
        nio = numIter;
        newTh1 =  max(min(baseTheta(1) -rand()*pi/2 + pi/4, pi),-pi); 
        newTh2 = max(min(baseTheta(2) -rand()*pi/2 + pi/4, pi),-pi); 
        newTh3 = max(min(baseTheta(3) -rand()*pi/2 + pi/4, pi),-pi); 
        
        newTh1G =  max(min(baseThetaG(1) -rand()*pi/2 + pi/4, pi),-pi); 
        newTh2G = max(min(baseThetaG(2) -rand()*pi/2 + pi/4, pi),-pi); 
        newTh3G = max(min(baseThetaG(3) -rand()*pi/2 + pi/4, pi),-pi); 
        
        theta = [newTh1, newTh2, newTh3];
        thetaG = [newTh1G, newTh2G, newTh3G];

        
        distanceVec =(thetaTree(1,:) - theta(1)).^2+ (thetaTree(2,:)-theta(2)).^2+(thetaTree(3,:)-theta(3)).^2;
        [val, ind] = min(distanceVec);
       nearestTh = thetaTree(:,ind);
       temp = theta' - nearestTh;
       amp = sqrt(sum(temp.^2));
       steps = ceil(amp/.25);
       thetaVec = temp./(amp*4);    
       newNode = getEndPosition(theta, armLengths)';
       count = count +1;
       theta = nearestTh+thetaVec;
       for iii=1:steps
           if ~getColisions(nearestTh, theta, circles) && iii~=steps
               nearestTh = theta;
               theta = theta + thetaVec;
           elseif iii~= 1 | iii == steps
               numIter = numIter +1;
                    theta = theta - thetaVec;
                    thetaTree = [thetaTree, theta];
                    edgeMat(ind, length(thetaTree)) = val;
                    edgeMat(length(thetaTree), ind) = val;
                    nearestTh = thetaTree(:,ind);
                     plot3([theta(1) nearestTh(1)], [theta(2) nearestTh(2)],...
                     [theta(3) nearestTh(3)], 'ko-', 'MarkerSize', 2);  
                    distanceVec =(thetaTreeG(1,:) - theta(1)).^2+ (thetaTreeG(2,:)...
                -theta(2)).^2+(thetaTreeG(3,:)-theta(3)).^2;              
                [val, ind2] = min(distanceVec);
                if val < thresh
                    if ~getColisions(thetaTreeG(:,ind2), theta, circles)
                        nn = thetaTreeG(:,ind2);
                       goalFound = true;
                       connectNode1 = length(thetaTree);
                       connectNode2 = ind2;
                       distFin = val;
                        plot3([nn(1), theta(1)], [nn(2), theta(2)],[nn(3), theta(3)], 'ko-');
                    end
                end  
           end   
       end
       
       
        distanceVec =(thetaTreeG(1,:) - thetaG(1)).^2+ (thetaTreeG(2,:)...
            -thetaG(2)).^2+(thetaTreeG(3,:)-thetaG(3)).^2;
        
       [val, ind] = min(distanceVec);
       newNodeG = getEndPosition(thetaG, armLengths)';
       
       nearestTh = thetaTreeG(:,ind);
       temp = thetaG' - nearestTh;
       amp = sqrt(sum(temp.^2));
       steps = ceil(amp/.25);
       thetaVec = temp./(amp*4);    
       newNode = getEndPosition(theta, armLengths)';
       count = count +1;
       thetaG = nearestTh+thetaVec;
       for iii = 1:steps
           if ~getColisions(nearestTh, thetaG, circles) &&~goalFound && iii~=steps
                nearestTh = thetaG;
               thetaG = thetaG + thetaVec;
           elseif (iii~= 1 | iii == steps) &&~goalFound
               numIter = numIter +1;
                thetaG = thetaG - thetaVec;
                    thetaTreeG = [thetaTreeG, thetaG];
                    edgeMatG(ind, length(thetaTreeG)) = val;
                    edgeMatG(length(thetaTreeG), ind) = val;
                    nearestTh = thetaTreeG(:,ind);
                    plot3([thetaG(1) nearestTh(1)], [thetaG(2) nearestTh(2)],...
                        [thetaG(3) nearestTh(3)], 'ko-', 'MarkerSize', 2);  
                     distanceVec =(thetaTree(1,:) - thetaG(1)).^2+ (thetaTree(2,:)...
                -thetaG(2)).^2+(thetaTree(3,:)-thetaG(3)).^2;              
                [val, ind2] = min(distanceVec);
                 if val < thresh & ~goalFound
                     if ~getColisions(thetaTree(:, ind2), thetaG, circles)
                         nn = thetaTree(:,ind2);
                       goalFound = true;
                       connectNode1 = ind2;
                       connectNode2 = length(thetaTreeG);
                       distFin = val;
                       plot3([nn(1), thetaG(1)], [nn(2), thetaG(2)],[nn(3), thetaG(3)], 'ko-');
                     end
                end 

           end   
           if numIter ~= nio
              % writeVideo(obj, getframe(gcf));
           end
       end
       
       if count >=10
            newTh1 = rand()*2*pi-pi;
            newTh2 = rand()*2*pi-pi;
            newTh3 =rand()*2*pi-pi;
            temp = [newTh1;newTh2;newTh3];
           
            distanceVec =(thetaTree(1,:) - temp(1)).^2+ (thetaTree(2,:)...
                 -temp(2)).^2+(thetaTree(3,:)-temp(3)).^2;
           [~, minInd] = min(distanceVec);
           baseTheta = thetaTree(:, minInd);
           
           distanceVec =(thetaTreeG(1,:) - temp(1)).^2+ (thetaTreeG(2,:)...
                 -temp(2)).^2+(thetaTreeG(3,:)-temp(3)).^2;
           [~, minInd] = min(distanceVec);
           baseThetaG = thetaTreeG(:, minInd);
           count = 0;
       end
   end
   buffer = zeros(maxIter,maxIter);
   edgeMat = [edgeMat, buffer; buffer, edgeMatG];
   if goalFound
       edgeMat(connectNode1, connectNode2+maxIter) = distFin;
        edgeMat(connectNode2+maxIter, connectNode1) = distFin;
   end
   [rrrr, cccc] = size(thetaTreeG);

   thetaTree(:, maxIter+1:maxIter+cccc)=thetaTreeG;
 
   
   
   curInd = 1;
   newNodes = [1];
   explored = [];
   path = [1];
   c = PriorityQueue();
   c.insert(-1, path);
   curPath = [];
   curDist = inf;
   curThresh = .05;
   notfound = true;
   distanceVec =(thetaTree(1,:) - endNode(1)).^2+ (thetaTree(2,:)...
                 -endNode(2)).^2+(thetaTree(3,:)-endNode(3)).^2;
   [~, minInd] = min(distanceVec);
   while ~isempty(newNode) & size(c)~=0 & notfound
      [len, path] = c.pop();
      curInd = path(end);
      if curInd == minInd
          curPath = path;
          break;
      end
      explored = [explored, curInd];
      edges = edgeMat(:, curInd);
      indsNo = find(edges ~=0)';
      for i = indsNo
          if ~any(i == explored)
               pathn = [path, i];
              lenn = -1*edges(i) +len;
              dist = sum((endNode - thetaTree(:,i)).^2);
              if dist<curDist
                  curDist = dist;
                  curPath = pathn;
              end
              c.insert(lenn, pathn);
          end
      end
   end
   figure;
   endNodexy = getEndPosition(endNode, armLengths);
   startNodexy = getEndPosition(startNode, armLengths);
   thetaTree = [thetaTree, endNode];
     [rtr, ctr] = size(thetaTree)
   [rr, ~] = size(circles);
   for p  = [curPath, ctr]
       current_thetas = thetaTree(:, p);
       %finding the coordinates of joint1 
        joint1_x = armLengths(1) * cos(current_thetas(1));
        joint1_y = armLengths(1) * sin(current_thetas(1));
    
        %finding the coordinates of joint2
        joint2_x = joint1_x + armLengths(2) * cos(current_thetas(1) + current_thetas(2));
        joint2_y = joint1_y + armLengths(2) * sin(current_thetas(1) + current_thetas(2));
        
        %finding the location of endPoint
        endPosition_x = joint2_x + armLengths(3) * cos(current_thetas(1) + current_thetas(2) + current_thetas(3));
        endPosition_y = joint2_y + armLengths(3) * sin(current_thetas(1) + current_thetas(2) + current_thetas(3));
         plot(startNodexy(1), startNodexy(2), 'g.', 'MarkerSize', 20);
         hold on;
         plot(endNodexy(1), endNodexy(2), 'm.', 'MarkerSize', 20);
         
         plot([0.0 ; joint1_x], [0.0 ; joint1_y], 'o-'); hold on;
		 plot([joint1_x ; joint2_x], [joint1_y ; joint2_y], 'ro-'); hold on;
         plot([joint2_x ; endPosition_x], [joint2_y ; endPosition_y], 'bo-'); 
         for rrr = 1:2:rr
            plot(circles(rrr,:), circles(rrr+1,:), 'g-');
         end
         axis([-5,5,-5,5]);
         axis square
         axis equal 
         xlabel 'x-distance';
         ylabel 'y-distance';
         %writeVideo(obj2, getframe(gcf));
         hold off;
   end
   sum((getEndPosition(thetaTree(:,curPath(end)), armLengths)' - endNode).^2)
   t-cputime
   numIter
   length(curPath)
   
    moves = edgeMat;
    close(obj);
    close(obj2);
end
function isIntersect = getColisions(startNode, endTh, obstacles)
    endCoords = getEndPositions(endTh, [2,2,1]);
       endCoords2 = getEndPosition(startNode, [2,2,1])';
    endCoords = [[0;0], endCoords, endCoords2(1:2)];
    
    isIntersect = false;
    [row, ~] = size(obstacles);
    for r = 1:2:row
        obs = obstacles(r:r+1, :);
        for np = 1:4
            xy1 = endCoords(:,np:np+1);
            for nobs = 1:4
                if ~isIntersect
                    xy2 = obs(:, nobs:nobs+1);
                    isIntersect =  getIntersect(xy1, xy2);
                end
            end
        end
    end

end

function boolVal = getIntersect(vec1, vec2)
    x = [vec1(1,:)', vec2(1,:)'];%# Starting points in first row, ending points in second row
    y = [vec1(2,:)', vec2(2,:)'];
    dx = diff(x);  %# Take the differences down each column
    dy = diff(y);
    den = dx(1)*dy(2)-dy(1)*dx(2);  %# Precompute the denominator
    ua = (dx(2)*(y(1)-y(3))-dy(2)*(x(1)-x(3)))/den;
    ub = (dx(1)*(y(1)-y(3))-dy(1)*(x(1)-x(3)))/den;

    boolVal = all(([ua ub] >= 0) & ([ua ub] <= 1));

end