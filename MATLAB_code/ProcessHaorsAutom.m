function stats = ProcessHaorsAutom(inpath)

% close all;  % Close all figures (except those of imtool.)
% clearvars;  % Erase all existing variables. Or clearvars if you want.
format long g;
format compact;
fontSize = 13;
%% Input
for dd=1:1
    dt = datestr(now - days(dd),'yyyymmdd');    % run for prev day
    dtf = datestr(now  - days(dd),'yyyy-mm-dd') 
    infile = [inpath '2015-07-01'  '.tif'];
    
    if isfile(infile)
        
        % BW =imread('nebdMay22.tif'); str="May22"
        BWr=imread(infile); str='Automated_NEbd';BW = BWr; BW(BWr>2) = 0;


 
        BW =logical(BW);
        se2 = strel('disk',10);
        binaryImage=imopen(BW,se2);

        % figure,subplot(1,2,1)
        % imshow(BW)
        % title(['Binary image-' str],'FontSize', fontSize, 'Interpreter', 'None')
        % subplot(1,2,2)
        % imshow(binaryImage)
        % title('Erosion + Dilation','FontSize', fontSize, 'Interpreter', 'None')

        %%
        % Display the image.
        % figure
        % subplot(1, 2, 1);
        % imshow(binaryImage, []);
        % title('Erosion + Dilation', 'FontSize', fontSize, 'Interpreter', 'None');
        % axis on;

        % Fill holes

        binaryImage = bwconncomp(binaryImage);
        L = labelmatrix(binaryImage);

        % subplot(1, 2, 2);
        % imshow(label2rgb(L,'jet','k','shuffle'));
        % title(['Connected components-' str], 'FontSize', fontSize, 'Interpreter', 'None');

        % Let's measure things to see what we're starting with.
        props = regionprops(binaryImage, 'Solidity', 'Area','perimeter', 'Eccentricity','Circularity');
        allAreas = [props.Area];
        allSolidities = [props.Solidity];
        allEccentricity=[props.Eccentricity];
        allCircularities = 4 * pi * allAreas ./ [props.Perimeter] .^ 2;
        %% Get rid of blobs with low circularity.
        highCircularityIndexes = find( allAreas>=200000  & allEccentricity < 0.925 ... %No use of ecc for Planet
                                     | allAreas>2000 & allAreas<200000 & allCircularities>0.11 & allEccentricity < 0.95 );  %1 pixel area=100sq.m, here >0.2 sq km
        % highCircularityIndexes = find(allCircularities > 0.00   & allAreas>2000 & allEccentricity < 1);  %1 pixel area=100sq.m, here >0.2 sq km

        binaryImage3 = ismember(L, highCircularityIndexes);
        binaryImage3 = imfill(binaryImage3, 'holes');

        CC = bwconncomp(binaryImage3);
        LC = labelmatrix(CC);
        stats = regionprops(CC,'Area','Circularity');
        CC.NumObjects;


        % figure,imshow(label2rgb(LC,'jet','k','shuffle'));
        % title(['Haors- ' str] ,'FontSize', fontSize, 'Interpreter', 'None');
        %% areas
        x=[stats.Area].*1e-4;  % in sq km
        xt=x';
        vol=0.0118*([stats.Area].*1e-4);  %*0.0056 - 0.03; 
        volc=0.0115*([stats.Area].*1e-4);
        sum(vol)
        dlmwrite('Output_HaorVolume.txt',[str2num(dt) sum(vol)],'-append','precision', '%16f')

    end
    
end
%% figure, histogram((x),100);
% 
% numEd = 20;
%  [N,edges] = histcounts(log10(x),numEd); %[ log10(0.2) log10(0.3) log10(0.5) log10(0.8) log10(1) log10(2) log10(5) log10(10) log10(15) log10(20) log10(30) log10(40) log10(60) log10(80) log10(100) log10(150)]);
%  histogram(x,10.^edges,'Normalization','probability','FaceColor','#A4A4A4');
%  ylim([0,0.4]);
% %  title('(b) SAR-based'); %[str ' Probability distribution for Haor Area'],'FontSize', fontSize, 'Interpreter', 'None');
%  xlabel('Area, km^2')
%  ylabel('Probability')
%  set(gca, 'xscale','log')
%   a = get(gca,'XTickLabel');
% set(gca,'XTickLabel',a,'fontsize',15)
% 
% 
%  [N,edges] = histcounts(log10(vol),15); %[ log10(0.2) log10(0.3) log10(0.5) log10(0.8) log10(1) log10(2) log10(5) log10(10) log10(15) log10(20) log10(30) log10(40) log10(60) log10(80) log10(100) log10(150)]);
%  figure, histogram(vol,10.^edges,'Normalization','probability','FaceColor','#A4A4A4','LineStyle','--'	)
%  ylim([0,0.4]);
% %  title(['Probability distribution for Volume Change'],'FontSize', fontSize, 'Interpreter', 'None');
%  xlabel('Volume Storage, km^3')
%  ylabel('Frequency')
%  set(gca, 'xscale','log')
%    a = get(gca,'XTickLabel');
% set(gca,'XTickLabel',a,'fontsize',15)

%% Revised histograms - comment from Tamlin
% x=[stats.Area].*1e-4;  % in sq km
% xt=x';
% vol=0.0118*([stats.Area].*1e-4);  %*0.0056 - 0.03; 
% volc=0.0115*([stats.Area].*1e-4);
% numEd = 16;
% figure
% [N,edgesA] = histcounts(log10(x),numEd); %[ log10(0.2) log10(0.3) log10(0.5) log10(0.8) log10(1) log10(2) log10(5) log10(10) log10(15) log10(20) log10(30) log10(40) log10(60) log10(80) log10(100) log10(150)]);
% ha = histogram(x,10.^edgesA,'Normalization','probability','FaceColor','#A4A4A4','visible','off');
% 
% Axp = ha.Values;
% Ayp = ha.BinEdges(2:numEd+1);
% 
% 
% [N,edgesV] = histcounts(log10(vol),numEd); %[ log10(0.2) log10(0.3) log10(0.5) log10(0.8) log10(1) log10(2) log10(5) log10(10) log10(15) log10(20) log10(30) log10(40) log10(60) log10(80) log10(100) log10(150)]);
% hv = histogram(vol,10.^edgesV,'Normalization','probability','FaceColor','#A4A4A4','LineStyle','--','visible','off');
% Vxp = hv.Values;
% Vyp = hv.BinEdges(1:numEd);
% 
% 
% 
% % CDF
% x=[stats.Area].*1e-4;  % in sq km
% xt=x';
% vol=0.0118*([stats.Area].*1e-4);  %*0.0056 - 0.03; 
% volc=0.0115*([stats.Area].*1e-4);
% numEd = 16;
% 
% [N,edgesA] = histcounts(log10(x),numEd); %[ log10(0.2) log10(0.3) log10(0.5) log10(0.8) log10(1) log10(2) log10(5) log10(10) log10(15) log10(20) log10(30) log10(40) log10(60) log10(80) log10(100) log10(150)]);
% ha = histogram(x,10.^edgesA,'Normalization','cdf','FaceColor','#A4A4A4','visible','off');
% 
% Ax = ha.Values;
% Ay = ha.BinEdges(1:numEd);
% 
% 
% [N,edgesV] = histcounts(log10(vol),numEd); %[ log10(0.2) log10(0.3) log10(0.5) log10(0.8) log10(1) log10(2) log10(5) log10(10) log10(15) log10(20) log10(30) log10(40) log10(60) log10(80) log10(100) log10(150)]);
% hv = histogram(vol,10.^edgesV,'Normalization','cdf','FaceColor','#A4A4A4','LineStyle','--','visible','off'	);
% Vx = hv.Values;
% Vy = hv.BinEdges(1:numEd);
