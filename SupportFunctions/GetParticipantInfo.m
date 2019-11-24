function [ ParticipantInfo ] = GetParticipantInfo( )
%GetParticipantInfo M file to store participant information.
%   The type of information covered is Name, Trials, ETG Start time
%   Note: useTimingInfo irrelevant if the person's data has been recorded
%   in the old format. The old format exclusively uses timing.txt

%%
ParticipantInfo(1).Name = '1';
ParticipantInfo(1).Trials = [1, 2];
ParticipantInfo(1).OldStyle = 1;
ParticipantInfo(1).RealDepthPresent = 0;
ParticipantInfo(1).Age = 27;

ParticipantInfo(1).Start_h(1) = 18;
ParticipantInfo(1).Start_m(1) = 16;
ParticipantInfo(1).Start_s(1) = 24;
ParticipantInfo(1).useTimingInfo(1) = 0;

ParticipantInfo(1).Start_h(2) = 18;
ParticipantInfo(1).Start_m(2) = 27;
ParticipantInfo(1).Start_s(2) = 11;
ParticipantInfo(1).useTimingInfo(2) = 0;
%%
ParticipantInfo(2).Name = '2';
ParticipantInfo(2).Trials = [1, 2, 3];
ParticipantInfo(2).OldStyle = 1;
ParticipantInfo(2).RealDepthPresent = 0;
ParticipantInfo(2).Age = 18;

ParticipantInfo(2).Start_h(1) = 13;
ParticipantInfo(2).Start_m(1) = 24;
ParticipantInfo(2).Start_s(1) = 44;
ParticipantInfo(2).useTimingInfo(1) = 0;

ParticipantInfo(2).Start_h(2) = 13;
ParticipantInfo(2).Start_m(2) = 33;
ParticipantInfo(2).Start_s(2) = 52;
ParticipantInfo(2).useTimingInfo(2) = 0;

ParticipantInfo(2).Start_h(3) = 13;
ParticipantInfo(2).Start_m(3) = 45;
ParticipantInfo(2).Start_s(3) = 19;
ParticipantInfo(2).useTimingInfo(3) = 0;

%% 
ParticipantInfo(3).Name = '3';
ParticipantInfo(3).Trials = [1, 2];
ParticipantInfo(3).OldStyle = 1;
ParticipantInfo(3).RealDepthPresent = 0;
ParticipantInfo(3).Age = 19;

ParticipantInfo(3).Start_h(1) = 17;
ParticipantInfo(3).Start_m(1) = 08;
ParticipantInfo(3).Start_s(1) = 35;
ParticipantInfo(3).useTimingInfo(1) = 0;

ParticipantInfo(3).Start_h(2) = 17;
ParticipantInfo(3).Start_m(2) = 26;
ParticipantInfo(3).Start_s(2) = 44;
ParticipantInfo(3).useTimingInfo(2) = 0;

%% 
ParticipantInfo(4).Name = '4';
ParticipantInfo(4).Trials = [1, 3];
ParticipantInfo(4).OldStyle = 0;
ParticipantInfo(4).RealDepthPresent = 1;
ParticipantInfo(4).Age = 22;

ParticipantInfo(4).Start_h(1) = 12;
ParticipantInfo(4).Start_m(1) = 11;
ParticipantInfo(4).Start_s(1) = 46;
ParticipantInfo(4).useTimingInfo(1) = 1;

ParticipantInfo(4).Start_h(2) = 12;
ParticipantInfo(4).Start_m(2) = 18;
ParticipantInfo(4).Start_s(2) = 15;
ParticipantInfo(4).useTimingInfo(2) = 1;

ParticipantInfo(4).Start_h(3) = 12;
ParticipantInfo(4).Start_m(3) = 29;
ParticipantInfo(4).Start_s(3) = 41;
ParticipantInfo(4).useTimingInfo(3) = 1;


%% 
ParticipantInfo(5).Name = '5';
ParticipantInfo(5).Trials = [1, 3];
ParticipantInfo(5).OldStyle = 1;
ParticipantInfo(5).RealDepthPresent = 0;
ParticipantInfo(5).Age = 19;

ParticipantInfo(5).Start_h(1) = 13;
ParticipantInfo(5).Start_m(1) = 24;
ParticipantInfo(5).Start_s(1) = 46;
ParticipantInfo(5).useTimingInfo(1) = 1;

ParticipantInfo(5).Start_h(2) = 13;
ParticipantInfo(5).Start_m(2) = 34;
ParticipantInfo(5).Start_s(2) = 12;
ParticipantInfo(5).useTimingInfo(2) = 0;

ParticipantInfo(5).Start_h(3) = 13;
ParticipantInfo(5).Start_m(3) = 41;
ParticipantInfo(5).Start_s(3) = 17;
ParticipantInfo(5).useTimingInfo(3) = 0;

%% 
ParticipantInfo(6).Name = '6';
ParticipantInfo(6).Trials = [1, 2, 3];
ParticipantInfo(6).OldStyle = 0;
ParticipantInfo(6).RealDepthPresent = 1;
ParticipantInfo(6).Age = 18;

ParticipantInfo(6).Start_h(1) = 13;
ParticipantInfo(6).Start_m(1) = 19;
ParticipantInfo(6).Start_s(1) = 08;
ParticipantInfo(6).useTimingInfo(1) = 1;

ParticipantInfo(6).Start_h(2) = 13;
ParticipantInfo(6).Start_m(2) = 37;
ParticipantInfo(6).Start_s(2) = 02;
ParticipantInfo(6).useTimingInfo(2) = 1;

ParticipantInfo(6).Start_h(3) = 13;
ParticipantInfo(6).Start_m(3) = 44;
ParticipantInfo(6).Start_s(3) = 43;
ParticipantInfo(6).useTimingInfo(3) = 1;

%% 
ParticipantInfo(7).Name = '7';
ParticipantInfo(7).Trials = [1,];
ParticipantInfo(7).OldStyle = 0;
ParticipantInfo(7).RealDepthPresent = 1;
ParticipantInfo(7).Age = 21;

ParticipantInfo(7).Start_h(1) = 11;
ParticipantInfo(7).Start_m(1) = 16;
ParticipantInfo(7).Start_s(1) = 14.10154;

%%
ParticipantInfo(8).Name = '8';
ParticipantInfo(8).Trials = [1, 2, 3];
ParticipantInfo(8).OldStyle = 0;
ParticipantInfo(8).RealDepthPresent = 1;
ParticipantInfo(8).Age = 22;

ParticipantInfo(8).Start_h(1) = 15;
ParticipantInfo(8).Start_m(1) = 27;
ParticipantInfo(8).Start_s(1) = 33.9439876;
ParticipantInfo(8).useTimingInfo(1) = 0;

ParticipantInfo(8).Start_h(2) = 18;
ParticipantInfo(8).Start_m(2) = 20;
ParticipantInfo(8).Start_s(2) = 33.7722185;
ParticipantInfo(8).useTimingInfo(2) = 0;

ParticipantInfo(8).Start_h(3) = 18;
ParticipantInfo(8).Start_m(3) = 29;
ParticipantInfo(8).Start_s(3) = 59.673602;
ParticipantInfo(8).useTimingInfo(3) = 0;

%%
ParticipantInfo(9).Name = '9';
ParticipantInfo(9).Trials = [1, 2, 3];
ParticipantInfo(9).OldStyle = 0;
ParticipantInfo(9).RealDepthPresent = 1;
ParticipantInfo(9).Age = 22;

ParticipantInfo(9).Start_h(1) = 15;
ParticipantInfo(9).Start_m(1) = 47;
ParticipantInfo(9).Start_s(1) = 40.180621;
ParticipantInfo(9).useTimingInfo(1) = 0;

ParticipantInfo(9).Start_h(2) = 16;
ParticipantInfo(9).Start_m(2) = 02;
ParticipantInfo(9).Start_s(2) = 27.9413962;
ParticipantInfo(9).useTimingInfo(2) = 0;

ParticipantInfo(9).Start_h(3) = 16;
ParticipantInfo(9).Start_m(3) = 13;
ParticipantInfo(9).Start_s(3) = 20.20366;
ParticipantInfo(9).useTimingInfo(3) = 0;

%%
ParticipantInfo(10).Name = '10';
ParticipantInfo(10).Trials = [1, 2, 3, 4];
ParticipantInfo(10).OldStyle = 0;
ParticipantInfo(10).RealDepthPresent = 1;
ParticipantInfo(10).Age = 26;

ParticipantInfo(10).Start_h(1) = 18;
ParticipantInfo(10).Start_m(1) = 31;
ParticipantInfo(10).Start_s(1) = 05.3966777;
ParticipantInfo(10).useTimingInfo(1) = 0;

ParticipantInfo(10).Start_h(2) = 18;
ParticipantInfo(10).Start_m(2) = 42;
ParticipantInfo(10).Start_s(2) = 00.06129;
ParticipantInfo(10).useTimingInfo(2) = 0;

ParticipantInfo(10).Start_h(3) = 18;
ParticipantInfo(10).Start_m(3) = 51;
ParticipantInfo(10).Start_s(3) = 39.2110434;
ParticipantInfo(10).useTimingInfo(3) = 0;

ParticipantInfo(10).Start_h(4) = 18;
ParticipantInfo(10).Start_m(4) = 59;
ParticipantInfo(10).Start_s(4) = 30.52935;
ParticipantInfo(10).useTimingInfo(4) = 0;
%% 

ParticipantInfo(11).Name = '11';
ParticipantInfo(11).Trials = [1, 2, 4];
ParticipantInfo(11).OldStyle = 0;
ParticipantInfo(11).RealDepthPresent = 1;
ParticipantInfo(11).Age = 25;

ParticipantInfo(11).Start_h(1) = 15;
ParticipantInfo(11).Start_m(1) = 22;
ParticipantInfo(11).Start_s(1) = 34.47546;
ParticipantInfo(11).useTimingInfo(1) = 0;

ParticipantInfo(11).Start_h(2) = 15;
ParticipantInfo(11).Start_m(2) = 32;
ParticipantInfo(11).Start_s(2) = 20.518489;
ParticipantInfo(11).useTimingInfo(2) = 0;

ParticipantInfo(11).Start_h(4) = 15;
ParticipantInfo(11).Start_m(4) = 52;
ParticipantInfo(11).Start_s(4) = 28.44695;
ParticipantInfo(11).useTimingInfo(4) = 0;

%%
ParticipantInfo(12).Name = '12';
ParticipantInfo(12).Trials = [1, 2, 3, 4];
ParticipantInfo(12).OldStyle = 0;
ParticipantInfo(12).RealDepthPresent = 1;
ParticipantInfo(12).Age = 26;

ParticipantInfo(12).Start_h(1) = 17;
ParticipantInfo(12).Start_m(1) = 18;
ParticipantInfo(12).Start_s(1) = 36.062803;
ParticipantInfo(12).useTimingInfo(1) = 0;

ParticipantInfo(12).Start_h(2) = 17;
ParticipantInfo(12).Start_m(2) = 30;
ParticipantInfo(12).Start_s(2) = 22.97712;
ParticipantInfo(12).useTimingInfo(2) = 0;

ParticipantInfo(12).Start_h(3) = 17;
ParticipantInfo(12).Start_m(3) = 38;
ParticipantInfo(12).Start_s(3) = 29.57486;
ParticipantInfo(12).useTimingInfo(3) = 0;

ParticipantInfo(12).Start_h(4) = 17;
ParticipantInfo(12).Start_m(4) = 47;
ParticipantInfo(12).Start_s(4) = 30.90830;
ParticipantInfo(12).useTimingInfo(4) = 0;

%%
ParticipantInfo(13).Name = '13';
ParticipantInfo(13).Trials = [1, 2, 3, 4];
ParticipantInfo(13).OldStyle = 0;
ParticipantInfo(13).RealDepthPresent = 1;
ParticipantInfo(13).Age = 27;

ParticipantInfo(13).Start_h(1) = 17;
ParticipantInfo(13).Start_m(1) = 22;
ParticipantInfo(13).Start_s(1) = 57.9116669;
ParticipantInfo(13).useTimingInfo(1) = 0;

ParticipantInfo(13).Start_h(2) = 17;
ParticipantInfo(13).Start_m(2) = 33;
ParticipantInfo(13).Start_s(2) = 31.2292116;
ParticipantInfo(13).useTimingInfo(2) = 0;

ParticipantInfo(13).Start_h(3) = 17;
ParticipantInfo(13).Start_m(3) = 43;
ParticipantInfo(13).Start_s(3) = 55.524816;
ParticipantInfo(13).useTimingInfo(3) = 0;

ParticipantInfo(13).Start_h(4) = 17;
ParticipantInfo(13).Start_m(4) = 52;
ParticipantInfo(13).Start_s(4) = 11.1760561;
ParticipantInfo(13).useTimingInfo(4) = 0;

%%
ParticipantInfo(14).Name = '14';
ParticipantInfo(14).Trials = [1, 2, 3, 4];
ParticipantInfo(14).OldStyle = 0;
ParticipantInfo(14).RealDepthPresent = 1;
ParticipantInfo(14).Age = 23;

ParticipantInfo(14).Start_h(1) = 12;
ParticipantInfo(14).Start_m(1) = 11;
ParticipantInfo(14).Start_s(1) = 33.5542347;
ParticipantInfo(14).useTimingInfo(1) = 0;

ParticipantInfo(14).Start_h(2) = 12;
ParticipantInfo(14).Start_m(2) = 22;
ParticipantInfo(14).Start_s(2) = 07.4320579;
ParticipantInfo(14).useTimingInfo(2) = 0;

ParticipantInfo(14).Start_h(3) = 12;
ParticipantInfo(14).Start_m(3) = 32;
ParticipantInfo(14).Start_s(3) = 07.8866374;
ParticipantInfo(14).useTimingInfo(3) = 0;

ParticipantInfo(14).Start_h(4) = 12;
ParticipantInfo(14).Start_m(4) = 47;
ParticipantInfo(14).Start_s(4) = 23.5531926;
ParticipantInfo(14).useTimingInfo(4) = 0;

%%
ParticipantInfo(15).Name = '15';
ParticipantInfo(15).Trials = [1, 2, 3, 4];
ParticipantInfo(15).OldStyle = 0;
ParticipantInfo(15).RealDepthPresent = 1;
ParticipantInfo(15).Age = 22;

ParticipantInfo(15).Start_h(1) = 10;
ParticipantInfo(15).Start_m(1) = 27;
ParticipantInfo(15).Start_s(1) = 28.8597655;
ParticipantInfo(15).useTimingInfo(1) = 0;

ParticipantInfo(15).Start_h(2) = 10;
ParticipantInfo(15).Start_m(2) = 39;
ParticipantInfo(15).Start_s(2) = 38.7534585;
ParticipantInfo(15).useTimingInfo(2) = 0;

ParticipantInfo(15).Start_h(3) = 10;
ParticipantInfo(15).Start_m(3) = 48;
ParticipantInfo(15).Start_s(3) = 04.4634264;
ParticipantInfo(15).useTimingInfo(3) = 0;

ParticipantInfo(15).Start_h(4) = 10;
ParticipantInfo(15).Start_m(4) = 57;
ParticipantInfo(15).Start_s(4) = 50.2395277;
ParticipantInfo(15).useTimingInfo(4) = 0;

%%
ParticipantInfo(16).Name = '16';
ParticipantInfo(16).Trials = [1, 2, 3, 4];
ParticipantInfo(16).OldStyle = 0;
ParticipantInfo(16).RealDepthPresent = 1;
ParticipantInfo(16).Age = 22;

ParticipantInfo(16).Start_h(1) = 14;
ParticipantInfo(16).Start_m(1) = 22;
ParticipantInfo(16).Start_s(1) = 58.5002959;
ParticipantInfo(16).useTimingInfo(1) = 0;

ParticipantInfo(16).Start_h(2) = 14;
ParticipantInfo(16).Start_m(2) = 32;
ParticipantInfo(16).Start_s(2) = 24.2717083;
ParticipantInfo(16).useTimingInfo(2) = 0;

ParticipantInfo(16).Start_h(3) = 14;
ParticipantInfo(16).Start_m(3) = 42;
ParticipantInfo(16).Start_s(3) = 11.4554563;
ParticipantInfo(16).useTimingInfo(3) = 0;

ParticipantInfo(16).Start_h(4) = 14;
ParticipantInfo(16).Start_m(4) = 49;
ParticipantInfo(16).Start_s(4) = 38.4557147;
ParticipantInfo(16).useTimingInfo(4) = 0;

%%
ParticipantInfo(17).Name = '17';
ParticipantInfo(17).Trials = [1, 2, 3, 4];
ParticipantInfo(17).OldStyle = 0;
ParticipantInfo(17).RealDepthPresent = 1;
ParticipantInfo(17).Age = 23;

ParticipantInfo(17).Start_h(1) = 13;
ParticipantInfo(17).Start_m(1) = 11;
ParticipantInfo(17).Start_s(1) = 09.3769464;
ParticipantInfo(17).useTimingInfo(1) = 0;

ParticipantInfo(17).Start_h(2) = 13;
ParticipantInfo(17).Start_m(2) = 21;
ParticipantInfo(17).Start_s(2) = 08.357663;
ParticipantInfo(17).useTimingInfo(2) = 0;

ParticipantInfo(17).Start_h(3) = 13;
ParticipantInfo(17).Start_m(3) = 30;
ParticipantInfo(17).Start_s(3) = 48.9651706;
ParticipantInfo(17).useTimingInfo(3) = 0;

ParticipantInfo(17).Start_h(4) = 13;
ParticipantInfo(17).Start_m(4) = 38;
ParticipantInfo(17).Start_s(4) = 36.9336724;
ParticipantInfo(17).useTimingInfo(4) = 0;

%%
ParticipantInfo(18).Name = '18';
ParticipantInfo(18).Trials = [1, 2, 3, 4];
ParticipantInfo(18).OldStyle = 0;
ParticipantInfo(18).RealDepthPresent = 1;
ParticipantInfo(18).Age = 45;

ParticipantInfo(18).Start_h(1) = 15;
ParticipantInfo(18).Start_m(1) = 17;
ParticipantInfo(18).Start_s(1) = 23.7794805;
ParticipantInfo(18).useTimingInfo(1) = 0;

ParticipantInfo(18).Start_h(2) = 15;
ParticipantInfo(18).Start_m(2) = 26;
ParticipantInfo(18).Start_s(2) = 49.0449026;
ParticipantInfo(18).useTimingInfo(2) = 0;

ParticipantInfo(18).Start_h(3) = 15;
ParticipantInfo(18).Start_m(3) = 35;
ParticipantInfo(18).Start_s(3) = 19.663757;
ParticipantInfo(18).useTimingInfo(3) = 0;

ParticipantInfo(18).Start_h(4) = 15;
ParticipantInfo(18).Start_m(4) = 43;
ParticipantInfo(18).Start_s(4) = 57.9380221;
ParticipantInfo(18).useTimingInfo(4) = 0;

%%
ParticipantInfo(19).Name = '19';
ParticipantInfo(19).Trials = [1, 2, 3];
ParticipantInfo(19).OldStyle = 0;
ParticipantInfo(19).RealDepthPresent = 1;
ParticipantInfo(19).Age = 26;

ParticipantInfo(19).Start_h(1) = 17;
ParticipantInfo(19).Start_m(1) = 19;
ParticipantInfo(19).Start_s(1) = 04.6595938;
ParticipantInfo(19).useTimingInfo(1) = 0;

ParticipantInfo(19).Start_h(2) = 17;
ParticipantInfo(19).Start_m(2) = 30;
ParticipantInfo(19).Start_s(2) = 23.3388574;
ParticipantInfo(19).useTimingInfo(2) = 0;

ParticipantInfo(19).Start_h(3) = 17;
ParticipantInfo(19).Start_m(3) = 40;
ParticipantInfo(19).Start_s(3) = 33.677908;
ParticipantInfo(19).useTimingInfo(3) = 0;

ParticipantInfo(19).Start_h(4) = 17;
ParticipantInfo(19).Start_m(4) = 52;
ParticipantInfo(19).Start_s(4) = 11.1760561;
ParticipantInfo(19).useTimingInfo(4) = 0;

%%
ParticipantInfo(20).Name = '20';
ParticipantInfo(20).Trials = [1, 2, 3, 4];
ParticipantInfo(20).OldStyle = 0;
ParticipantInfo(20).RealDepthPresent = 1;
ParticipantInfo(20).Age = 55;

ParticipantInfo(20).Start_h(1) = 10;
ParticipantInfo(20).Start_m(1) = 15;
ParticipantInfo(20).Start_s(1) = 09.4036183;
ParticipantInfo(20).useTimingInfo(1) = 0;

ParticipantInfo(20).Start_h(2) = 10;
ParticipantInfo(20).Start_m(2) = 26;
ParticipantInfo(20).Start_s(2) = 43.117243;
ParticipantInfo(20).useTimingInfo(2) = 0;

ParticipantInfo(20).Start_h(3) = 10;
ParticipantInfo(20).Start_m(3) = 37;
ParticipantInfo(20).Start_s(3) = 39.0577707;
ParticipantInfo(20).useTimingInfo(3) = 0;

ParticipantInfo(20).Start_h(4) = 10;
ParticipantInfo(20).Start_m(4) = 51;
ParticipantInfo(20).Start_s(4) = 28.6172738;
ParticipantInfo(20).useTimingInfo(4) = 0;

%%
ParticipantInfo(21).Name = '21';
ParticipantInfo(21).Trials = [1, 2, 3, 4];
ParticipantInfo(21).OldStyle = 0;
ParticipantInfo(21).RealDepthPresent = 1;
ParticipantInfo(21).Age = 43;

ParticipantInfo(21).Start_h(1) = 13;
ParticipantInfo(21).Start_m(1) = 26;
ParticipantInfo(21).Start_s(1) = 08.7047358;
ParticipantInfo(21).useTimingInfo(1) = 0;

ParticipantInfo(21).Start_h(2) = 13;
ParticipantInfo(21).Start_m(2) = 37;
ParticipantInfo(21).Start_s(2) = 20.3557467;
ParticipantInfo(21).useTimingInfo(2) = 0;

ParticipantInfo(21).Start_h(3) = 13;
ParticipantInfo(21).Start_m(3) = 49;
ParticipantInfo(21).Start_s(3) = 42.4480221;
ParticipantInfo(21).useTimingInfo(3) = 0;

ParticipantInfo(21).Start_h(4) = 14;
ParticipantInfo(21).Start_m(4) = 01;
ParticipantInfo(21).Start_s(4) = 51.8169858;
ParticipantInfo(21).useTimingInfo(4) = 0;

%%
ParticipantInfo(22).Name = '22';
ParticipantInfo(22).Trials = [1, 2, 3, 4];
ParticipantInfo(22).OldStyle = 0;
ParticipantInfo(22).RealDepthPresent = 1;
ParticipantInfo(22).Age = 54;

ParticipantInfo(22).Start_h(1) = 15;
ParticipantInfo(22).Start_m(1) = 26;
ParticipantInfo(22).Start_s(1) = 48.2263882;
ParticipantInfo(22).useTimingInfo(1) = 0;

ParticipantInfo(22).Start_h(2) = 15;
ParticipantInfo(22).Start_m(2) = 38;
ParticipantInfo(22).Start_s(2) = 28.2889028;
ParticipantInfo(22).useTimingInfo(2) = 0;

ParticipantInfo(22).Start_h(3) = 15;
ParticipantInfo(22).Start_m(3) = 49;
ParticipantInfo(22).Start_s(3) = 57.0675511;
ParticipantInfo(22).useTimingInfo(3) = 0;

ParticipantInfo(22).Start_h(4) = 16;
ParticipantInfo(22).Start_m(4) = 00;
ParticipantInfo(22).Start_s(4) = 58.4926093;
ParticipantInfo(22).useTimingInfo(4) = 0;

%%
ParticipantInfo(23).Name = '23';
ParticipantInfo(23).Trials = [1, 2, 3, 4];
ParticipantInfo(23).OldStyle = 0;
ParticipantInfo(23).RealDepthPresent = 1;
ParticipantInfo(23).Age = 60;

ParticipantInfo(23).Start_h(1) = 15;
ParticipantInfo(23).Start_m(1) = 24;
ParticipantInfo(23).Start_s(1) = 12.5000246;
ParticipantInfo(23).useTimingInfo(1) = 0;

ParticipantInfo(23).Start_h(2) = 15;
ParticipantInfo(23).Start_m(2) = 34;
ParticipantInfo(23).Start_s(2) = 55.790695;
ParticipantInfo(23).useTimingInfo(2) = 0;

ParticipantInfo(23).Start_h(3) = 15;
ParticipantInfo(23).Start_m(3) = 42;
ParticipantInfo(23).Start_s(3) = 53.3756807;
ParticipantInfo(23).useTimingInfo(3) = 0;

ParticipantInfo(23).Start_h(4) = 15;
ParticipantInfo(23).Start_m(4) = 57;
ParticipantInfo(23).Start_s(4) = 33.6423633;
ParticipantInfo(23).useTimingInfo(4) = 0;

%---------------------------------------%
%% IRRELEVANT - Please ignore
%ParticipantInfo(41).Name = '41';
%ParticipantInfo(41).Trials = [1, 2];
%ParticipantInfo(41).OldStyle = 2;
%ParticipantInfo(41).RealDepthPresent = 0;
%ParticipantInfo(41).Age = 22;
end