%% getting started---------------------------------------------------------
clear all           %clear all existing variables
clc                 %clear command window
close all           %close all opened figure

%% get data table from their function--------------------------------------
tic
accTab = acc();
lfpTab = lfp();
hrTab = hr();
toc

%% transform table into timetable------------------------------------------
accT = table2timetable(accTab);
lfpT = table2timetable(lfpTab);
hrT = table2timetable(hrTab);


%% create merged table-----------------------------------------------------
mergeT = synchronize(accT, hrT, lfpT, 'union','previous');
mergeT.Properties.VariableNames = ...
    {'Total acceleration','X-axis','Y-axis','Z-axis',...
    'Heart rate','LFP left','LFP right'};
%% plotting the merged table-----------------------------------------------
s = stackedplot(mergeT);

s.LineProperties(1).PlotType = "plot";
s.LineProperties(1).Color = '#b18380';

s.LineProperties(2).PlotType = "plot";
s.LineProperties(2).Color = '#ca8fa3';

s.LineProperties(3).PlotType = "plot";
s.LineProperties(3).Color = '#a280ae';

s.LineProperties(4).PlotType = "plot";
s.LineProperties(4).Color = '#7675aa';

s.LineProperties(5).PlotType = "plot";
s.LineProperties(5).Color = '#7dadb8';

s.LineProperties(6).PlotType = "stairs";
s.LineProperties(6).Color = '#79a68c';

s.LineProperties(7).PlotType = "stairs";
s.LineProperties(7).Color = '#808080';

%% functions---------------------------------------------------------------

function [accTab] = acc()
%% get data from csv files-------------------------------------------------
mat1 = readmatrix("nb02_ex01_accel1.csv");
mat2 = readmatrix("nb02_ex01_accel2.csv");
mat3 = readmatrix("nb02_ex01_accel3.csv");
mat4 = readmatrix("nb02_ex01_accel4.csv");

%% extract components------------------------------------------------------
t1 = mat1(:,1); x1 = mat1(:,2); y1 = mat1(:,3); z1 = mat1(:,4);
t2 = mat2(:,1); x2 = mat2(:,2); y2 = mat2(:,3); z2 = mat2(:,4);
t3 = mat3(:,1); x3 = mat3(:,2); y3 = mat3(:,3); z3 = mat3(:,4);
t4 = mat4(:,1); x4 = mat4(:,2); y4 = mat4(:,3); z4 = mat4(:,4);

%% calculate total acceleration--------------------------------------------
acc1 = sqrt(x1.^2 + y1.^2 + z1.^2 );
acc2 = sqrt(x2.^2 + y2.^2 + z2.^2 );
acc3 = sqrt(x3.^2 + y3.^2 + z3.^2 );
acc4 = sqrt(x4.^2 + y4.^2 + z4.^2 );

%% merge accelerations and time--------------------------------------------
time = [t1; t2; t3; t4];
acc = [acc1; acc2; acc3; acc4];
x = [x1; x2; x3; x4];
y = [y1; y2; y3; x4];
z = [z1; z2; z3; z4];

%% convert timestamps------------------------------------------------------
t = datetime(time,'ConvertFrom', 'posixtime','TimeZone','local');
tRed = dateshift(t,'start','minute');   %resolution = minutes

%% merge new time with acceleration----------------------------------------
tab = table(tRed,acc,x,y,z,'VariableNames',{'time', 'acc','x','y','z'});

%% merging all date that are similar
% unqdate = array of unique datetime
% a = array of index were there's a change
% idx = index given for each similar datetime

[unqdate, a, idx] = unique(tab.time);   %check for uniqueness of datetime
m = max(idx);                           %get how many dates are unique
sumAcc = accumarray(idx, tab.acc);      %sum of all values per idx
sumX = accumarray(idx, tab.x);
sumY = accumarray(idx, tab.y);
sumZ = accumarray(idx, tab.z);
a(end+1) = length(acc);                 %add the last index 

%calculate the number of value between two index and put it in a new vector
for i=1:1:m
    b(i,1) = (a(i+1)-a(i));
end

avgAcc = sumAcc./b;     %calculate average total acc for similar datetime
avgX = sumX./b;         %calculate average x-axis acc for similar datetime
avgY = sumY./b;         %calculate average y-axis acc for similar datetime
avgZ = sumZ./b;         %calculate average z-axis acc for similar datetime

%% create timetable of new time and new accelerations

accTab = table(unqdate, avgAcc, avgX, avgY, avgZ,...
    'VariableNames',{'time', 'avgAcc', 'avgX', 'avgY', 'avgZ'});

plot(accTab, 'time', 'avgAcc')
hold on
plot(accTab, 'time', 'avgX')
hold on
plot(accTab, 'time', 'avgY')
hold on
plot(accTab, 'time', 'avgZ')
hold on
end

function [lfpTab] = lfp()
%% get data from csv files-------------------------------------------------

lfpL = readmatrix('nb01_ex01_lfp_trend_left.csv');  %lfp left data
lfpR = readmatrix("nb01_ex01_lfp_trend_right.csv"); %lfp right data


%% extract data from lfp files---------------------------------------------

time_l = lfpL(:,1);     %time left
current_l = lfpL(:,2);  %current left
left = lfpL(:,3);       %lfp left

time_r = lfpR(:,1);     %time right
current_r = lfpR(:,2);  %current right
right = lfpR(:,3);      %lfp right

%/!\ Assumed that time is the same for lfp left AND lfp right

n = length(time_l);     %length of vector

%% getting ride of the outliers--------------------------------------------


for r=1:n
    if left(r) > 10000
        left(r) = nan;
    end
end

for u=1:1:n

    if right(u) > 10000
        right(u) = nan;
    end
end
% %normalization of LFP value
% left = left/max(left);
% right = right/max(right);

%% datetime conversion-----------------------------------------------------


t = datetime(time_l, 'ConvertFrom', 'posixtime','TimeZone','local');
time = dateshift(t,'start','minute');


%% merging data in a timetable---------------------------------------------
lfpTab = table(time, left, right);

end

function [hrTab] = hr()
%% get data from csv files-------------------------------------------------
hr = readmatrix("nb02_ex01_heartrate.csv");         %heart rate data
n = length(hr);

%%
time = datetime(hr(:,1), 'ConvertFrom', 'posixtime','TimeZone','local');

%%
time = dateshift(time,'start','minute');
tab = table(time,hr(:,2));

%% Summing the values is the default of accumarray
[unqdate, a, idx] = unique(tab.time);
m = max(idx);
val1 = accumarray(idx, tab.Var2);
a(end+1) = n;
%%
for i=1:1:m

    b(i,1) = (a(i+1)-a(i));
end

Avg = val1./b;

%%
hrTab = table(unqdate, Avg);
% plot(unqdate,Avg)
end