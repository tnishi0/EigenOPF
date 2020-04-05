function mpc = test_system_16gen
%TEST_SYSTEM_3GEN   3-generator test system.
%   mpc = TEST_SYSTEM_3GEN generates struct mpc containing the power flow
%   data for a 9-bus, 3-generator system. This is the 9-bus system in
%   Example 2.6 of Ref. [1]. Adapted from case9.m, which is distributed
%   with the MATPOWER package, by adding dynamic parameters.
%
%   Reference: [1] P.M. Anderson and A.A. Fouad, Power system control and
%   stability (IEEE Press, 2nd edition, 2003).

%
% Copyright (C) 2015  Takashi Nishikawa
% 
% This program is free software; you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation; either version 2 of the License, or (at
% your option) any later version.
% 
% This program is distributed in the hope that it will be useful, but
% WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
% General Public License for more details.
% 
% You should have received a copy of the GNU General Public License
% along with this program; if not, write to the Free Software
% Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307,
% USA.

%   Last modified by Takashi Nishikawa on 1/22/2015

%% system reference frequency (Hz)
mpc.ref_freq = 60;

%% generator dynamic parameters

Ks=20*ones(16,1); Ks(9)=12; Ks(13:16)=[0;0;0;0];
T1=0.15*ones(16,1); T1(9)=0.09; T1(13:16)=[0;0;0;0];
T2=0.04*ones(16,1); T2(9)=0.02; T2(13:16)=[0;0;0;0];
T3=0.15*ones(16,1); T3(9)=0.09; T3(13:16)=[0;0;0;0];
T4=0.04*ones(16,1); T4(9)=0.02; T4(13:16)=[0;0;0;0];
[Ka_red,Ks_red] = ExcitorRed(200*ones(16,1),0.01*ones(16,1),0.01*ones(16,1),ones(16,1),ones(16,1),Ks,T1,T2,T3,T4);

mpc.gen_dyn(:,1) = [0.186;0.186;0.3717;0.3052;0.396;0.4;0.294;0.342;0.513;0.297;0.306;0.465;0.275;0.248;0.248;0.284]; % xdp
mpc.gen_dyn(:,2) = [0.6;0.6;1.7465;1.834;1.98;2.032;1.77;1.74;1.8954;1.0985;2.176;1.515;1.48;1.566;1.566;1.424;]; % xd
mpc.gen_dyn(:,3)=[0.25;0.25;0.5;0.41;0.53;0.54;0.4;0.46;0.69;0.4;0.41;0.63;0.37;0.33;0.33;0.38];    % xqp
mpc.gen_dyn(:,4) =[0.414;0.414;1.659;1.806;1.86;1.928;1.752;1.68;1.845;0.7475;2.091;1.425;1.43;1.5051;1.5051;1.336];    %xq
mpc.gen_dyn(:,5) = [7;7;5.1143;4.0857;4.3333;4.35;4.4;4.05;3.8333;4.7692;1.6588;6.1533;4.96;3.4483;3.4483;5.625]; % H
mpc.gen_dyn(:,6) = [0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0]; %D
mpc.gen_dyn(:,7) = [10.2;10.2;5.7;5.69;5.4;7.3;5.66;6.7;4.79;9.37;4.1;7.4;5.9;4.1;4.1;7.8];  % Td0p
mpc.gen_dyn(:,8) = [1.5;1.5;1.5;1.5;0.44;0.4;1.5;0.41;1.96;1.5;1.5;1.5;1.5;1.5;1.5;1.5];  % Tq0p
mpc.gen_dyn(:,9) = Ka_red; % Ka
mpc.gen_dyn(:,10)= Ks_red;   % Ks
mpc.gen_dyn(:,11)= [600;600;700;700;600;800;600;600;900;650;1700;1500;10000;8700;8700;8000]; % Sb

%% MATPOWER Case Format : Version 2
mpc.version = '2';

%%-----  Power Flow Data  -----%%
%% system MVA base
mpc.baseMVA = 100;

%% bus data
%	bus_i	type	Pd	Qd	Gs	Bs	area	Vm	Va	baseKV	zone	Vmax	Vmin
mpc.bus = [
	1	2	0	0	0	0	0	1.045	0	230	1	1.1	0.9
2	2	0	0	0	0	0	0.98	0	230	1	1.1	0.9
3	2	0	0	0	0	0	0.983	0	230	1	1.1	0.9
4	2	0	0	0	0	0	0.997	0	230	1	1.1	0.9
5	2	0	0	0	0	0	1.011	0	230	1	1.1	0.9
6	2	0	0	0	0	0	1.05	0	230	1	1.1	0.9
7	2	0	0	0	0	0	1.063	0	230	1	1.1	0.9
8	2	0	0	0	0	0	1.03	0	230	1	1.1	0.9
9	2	0	0	0	0	0	1.025	0	230	1	1.1	0.9
10	2	0	0	0	0	0	1.01	0	230	1	1.1	0.9
11	2	0	0	0	0	0	1	0	230	1	1.1	0.9
12	2	0	0	0	0	0	1.0156	0	230	1	1.1	0.9
13	2	0	0	0	0	0	1.011	0	230	1	1.1	0.9
14	2	0	0	0	0	0	1	0	230	1	1.1	0.9
15	2	0	0	0	0	0	1	0	230	1	1.1	0.9
16	3	0	0	0	0	0	1	0	230	1	1.1	0.9
17	1	6000	300	0	0	0	1	0	230	1	1.1	0.9
18	1	2470	123	0	0	0	1	0	230	1	1.1	0.9
19	1	0	0	0	0	0	1	0	230	1	1.1	0.9
20	1	680	103	0	0	0	1	0	230	1	1.1	0.9
21	1	274	115	0	0	0	1	0	230	1	1.1	0.9
22	1	0	0	0	0	0	1	0	230	1	1.1	0.9
23	1	248	85	0	0	0	1	0	230	1	1.1	0.9
24	1	309	-92	0	0	0	1	0	230	1	1.1	0.9
25	1	224	47	0	0	0	1	0	230	1	1.1	0.9
26	1	139	17	0	0	0	1	0	230	1	1.1	0.9
27	1	281	76	0	0	0	1	0	230	1	1.1	0.9
28	1	206	28	0	0	0	1	0	230	1	1.1	0.9
29	1	284	27	0	0	0	1	0	230	1	1.1	0.9
30	1	0	0	0	0	0	1	0	230	1	1.1	0.9
31	1	0	0	0	0	0	1	0	230	1	1.1	0.9
32	1	0	0	0	0	0	1	0	230	1	1.1	0.9
33	1	112	0	0	0	0	1	0	230	1	1.1	0.9
34	1	0	0	0	0	0	1	0	230	1	1.1	0.9
35	1	0	0	0	0	0	1	0	230	1	1.1	0.9
36	1	102	-19.46	0	0	0	1	0	230	1	1.1	0.9
37	1	0	0	0	0	0	1	0	230	1	1.1	0.9
38	1	0	0	0	0	0	1	0	230	1	1.1	0.9
39	1	267	12.6	0	0	0	1	0	230	1	1.1	0.9
40	1	65.63	23.53	0	0	0	1	0	230	1	1.1	0.9
41	1	1000	250	0	0	0	1	0	230	1	1.1	0.9
42	1	1150	250	0	0	0	1	0	230	1	1.1	0.9
43	1	0	0	0	0	0	1	0	230	1	1.1	0.9
44	1	267.55	4.84	0	0	0	1	0	230	1	1.1	0.9
45	1	208	21	0	0	0	1	0	230	1	1.1	0.9
46	1	150.7	28.5	0	0	0	1	0	230	1	1.1	0.9
47	1	203.12	32.59	0	0	0	1	0	230	1	1.1	0.9
48	1	241.2	2.2	0	0	0	1	0	230	1	1.1	0.9
49	1	164	29	0	0	0	1	0	230	1	1.1	0.9
50	1	100	-147	0	0	0	1	0	230	1	1.1	0.9
51	1	337	-122	0	0	0	1	0	230	1	1.1	0.9
52	1	158	30	0	0	0	1	0	230	1	1.1	0.9
53	1	252.7	118.56	0	0	0	1	0	230	1	1.1	0.9
54	1	0	0	0	0	0	1	0	230	1	1.1	0.9
55	1	322	2	0	0	0	1	0	230	1	1.1	0.9
56	1	200	73.6	0	0	0	1	0	230	1	1.1	0.9
57	1	0	0	0	0	0	1	0	230	1	1.1	0.9
58	1	0	0	0	0	0	1	0	230	1	1.1	0.9
59	1	234	84	0	0	0	1	0	230	1	1.1	0.9
60	1	208.8	70.8	0	0	0	1	0	230	1	1.1	0.9
61	1	104	125	0	0	0	1	0	230	1	1.1	0.9
62	1	0	0	0	0	0	1	0	230	1	1.1	0.9
63	1	0	0	0	0	0	1	0	230	1	1.1	0.9
64	1	9	88	0	0	0	1	0	230	1	1.1	0.9
65	1	0	0	0	0	0	1	0	230	1	1.1	0.9
66	1	0	0	0	0	0	1	0	230	1	1.1	0.9
67	1	320	153	0	0	0	1	0	230	1	1.1	0.9
68	1	329	32	0	0	0	1	0	230	1	1.1	0.9
];


%% generator data
%	bus	Pg	Qg	Qmax	Qmin	Vg	mBase	status	Pmax	Pmin	Pc1	Pc2	Qc1min	Qc1max	Qc2min	Qc2max	ramp_agc	ramp_10	ramp_30	ramp_q	apf
mpc.gen = [
1	250	0	1000	0	1.045	600	1	300	0	0	0	0	0	0	0	0	0	0	0	0
2	545	0	1000	0	0.98	600	1	654	0	0	0	0	0	0	0	0	0	0	0	0
3	650	0	1000	0	0.983	700	1	780	0	0	0	0	0	0	0	0	0	0	0	0
4	632	0	1000	0	0.997	700	1	758.4	0	0	0	0	0	0	0	0	0	0	0	0
5	505	0	1000	0	1.011	600	1	606	0	0	0	0	0	0	0	0	0	0	0	0
6	700	0	1000	0	1.05	800	1	840	0	0	0	0	0	0	0	0	0	0	0	0
7	560	0	1000	0	1.063	600	1	672	0	0	0	0	0	0	0	0	0	0	0	0
8	540	0	1000	0	1.03	600	1	648	0	0	0	0	0	0	0	0	0	0	0	0
9	800	0	1000	0	1.025	900	1	960	0	0	0	0	0	0	0	0	0	0	0	0
10	500	0	1000	0	1.01	650	1	600	0	0	0	0	0	0	0	0	0	0	0	0
11	1000	0	1000	0	1	1700	1	1200	0	0	0	0	0	0	0	0	0	0	0	0
12	1350	0	1000	0	1.0156	1500	1	1620	0	0	0	0	0	0	0	0	0	0	0	0
13	3591	0	1000	0	1.011	10000	1	4309.2	0	0	0	0	0	0	0	0	0	0	0	0
14	1785	0	1000	0	1	8700	1	2142	0	0	0	0	0	0	0	0	0	0	0	0
15	1000	0	1000	0	1	8700	1	1200	0	0	0	0	0	0	0	0	0	0	0	0
16	4000	0	1000	0	1	8000	1	4800	0	0	0	0	0	0	0	0	0	0	0	0
];


%% branch data
%	fbus	tbus	r	x	b	rateA	rateB	rateC	ratio	angle	status	angmin	angmax
mpc.branch = [
1	54	0	0.0181	0	1000	1000	1000	1.025	0	1	-360	360
2	58	0	0.025	0	1000	1000	1000	1.07	0	1	-360	360
3	62	0	0.02	0	1000	1000	1000	1.07	0	1	-360	360
4	19	0.0007	0.0142	0	1000	1000	1000	1.07	0	1	-360	360
5	20	0.0009	0.018	0	1000	1000	1000	1.009	0	1	-360	360
6	22	0	0.0143	0	1000	1000	1000	1.025	0	1	-360	360
7	23	0.0005	0.0272	0	1000	1000	1000	0	0	1	-360	360
8	25	0.0006	0.0232	0	1000	1000	1000	1.025	0	1	-360	360
9	29	0.0008	0.0156	0	1000	1000	1000	1.025	0	1	-360	360
10	31	0	0.026	0	1000	1000	1000	1.04	0	1	-360	360
11	32	0	0.013	0	1000	1000	1000	1.04	0	1	-360	360
12	36	0	0.0075	0	1000	1000	1000	1.04	0	1	-360	360
13	17	0	0.0033	0	1000	1000	1000	1.04	0	1	-360	360
14	41	0	0.0015	0	1000	1000	1000	1	0	1	-360	360
15	42	0	0.0015	0	1000	1000	1000	1	0	1	-360	360
16	18	0	0.003	0	1000	1000	1000	1	0	1	-360	360
17	36	0.0005	0.0045	0.32	1000	1000	1000	0	0	1	-360	360
18	49	0.0076	0.1141	1.16	1000	1000	1000	0	0	1	-360	360
18	50	0.0012	0.0288	2.06	1000	1000	1000	0	0	1	-360	360
19	68	0.0016	0.0195	0.304	1000	1000	1000	0	0	1	-360	360
20	19	0.0007	0.0138	0	1000	1000	1000	1.06	0	1	-360	360
21	68	0.0008	0.0135	0.2548	1000	1000	1000	0	0	1	-360	360
22	21	0.0008	0.014	0.2565	1000	1000	1000	0	0	1	-360	360
23	22	0.0006	0.0096	0.1846	1000	1000	1000	0	0	1	-360	360
24	23	0.0022	0.035	0.361	1000	1000	1000	0	0	1	-360	360
24	68	0.0003	0.0059	0.068	1000	1000	1000	0	0	1	-360	360
25	54	0.007	0.0086	0.146	1000	1000	1000	0	0	1	-360	360
26	25	0.0032	0.0323	0.531	1000	1000	1000	0	0	1	-360	360
27	37	0.0013	0.0173	0.3216	1000	1000	1000	0	0	1	-360	360
27	26	0.0014	0.0147	0.2396	1000	1000	1000	0	0	1	-360	360
28	26	0.0043	0.0474	0.7802	1000	1000	1000	0	0	1	-360	360
29	26	0.0057	0.0625	1.029	1000	1000	1000	0	0	1	-360	360
29	28	0.0014	0.0151	0.249	1000	1000	1000	0	0	1	-360	360
30	53	0.0008	0.0074	0.48	1000	1000	1000	0	0	1	-360	360
30	61	0.00095	0.00915	0.58	1000	1000	1000	0	0	1	-360	360
31	30	0.0013	0.0187	0.333	1000	1000	1000	0	0	1	-360	360
31	53	0.0016	0.0163	0.25	1000	1000	1000	0	0	1	-360	360
32	30	0.0024	0.0288	0.488	1000	1000	1000	0	0	1	-360	360
33	32	0.0008	0.0099	0.168	1000	1000	1000	0	0	1	-360	360
34	33	0.0011	0.0157	0.202	1000	1000	1000	0	0	1	-360	360
34	35	0.0001	0.0074	0	1000	1000	1000	0.946	0	1	-360	360
36	34	0.0033	0.0111	1.45	1000	1000	1000	0	0	1	-360	360
36	61	0.0011	0.0098	0.68	1000	1000	1000	0	0	1	-360	360
37	68	0.0007	0.0089	0.1342	1000	1000	1000	0	0	1	-360	360
38	31	0.0011	0.0147	0.247	1000	1000	1000	0	0	1	-360	360
38	33	0.0036	0.0444	0.693	1000	1000	1000	0	0	1	-360	360
40	41	0.006	0.084	3.15	1000	1000	1000	0	0	1	-360	360
40	48	0.002	0.022	1.28	1000	1000	1000	0	0	1	-360	360
41	42	0.004	0.06	2.25	1000	1000	1000	0	0	1	-360	360
42	18	0.004	0.06	2.25	1000	1000	1000	0	0	1	-360	360
43	17	0.0005	0.0276	0	1000	1000	1000	0	0	1	-360	360
44	39	0	0.0411	0	1000	1000	1000	0	0	1	-360	360
44	43	0.0001	0.0011	0	1000	1000	1000	0	0	1	-360	360
45	35	0.0007	0.0175	1.39	1000	1000	1000	0	0	1	-360	360
45	39	0	0.0839	0	1000	1000	1000	0	0	1	-360	360
45	44	0.0025	0.073	0	1000	1000	1000	0	0	1	-360	360
46	38	0.0022	0.0284	0.43	1000	1000	1000	0	0	1	-360	360
47	53	0.0013	0.0188	1.31	1000	1000	1000	0	0	1	-360	360
48	47	0.00125	0.0134	0.8	1000	1000	1000	0	0	1	-360	360
49	46	0.0018	0.0274	0.27	1000	1000	1000	0	0	1	-360	360
51	45	0.0004	0.0105	0.72	1000	1000	1000	0	0	1	-360	360
51	50	0.0009	0.0221	1.62	1000	1000	1000	0	0	1	-360	360
52	37	0.0007	0.0082	0.1319	1000	1000	1000	0	0	1	-360	360
52	55	0.0011	0.0133	0.2138	1000	1000	1000	0	0	1	-360	360
54	53	0.0035	0.0411	0.6987	1000	1000	1000	0	0	1	-360	360
55	54	0.0013	0.0151	0.2572	1000	1000	1000	0	0	1	-360	360
56	55	0.0013	0.0213	0.2214	1000	1000	1000	0	0	1	-360	360
57	56	0.0008	0.0128	0.1342	1000	1000	1000	0	0	1	-360	360
58	57	0.0002	0.0026	0.0434	1000	1000	1000	0	0	1	-360	360
59	58	0.0006	0.0092	0.113	1000	1000	1000	0	0	1	-360	360
60	57	0.0008	0.0112	0.1476	1000	1000	1000	0	0	1	-360	360
60	59	0.0004	0.0046	0.078	1000	1000	1000	0	0	1	-360	360
61	60	0.0023	0.0363	0.3804	1000	1000	1000	0	0	1	-360	360
63	58	0.0007	0.0082	0.1389	1000	1000	1000	0	0	1	-360	360
63	62	0.0004	0.0043	0.0729	1000	1000	1000	0	0	1	-360	360
63	64	0.0016	0.0435	0	1000	1000	1000	1.06	0	1	-360	360
65	62	0.0004	0.0043	0.0729	1000	1000	1000	0	0	1	-360	360
65	64	0.0016	0.0435	0	1000	1000	1000	1.06	0	1	-360	360
66	56	0.0008	0.0129	0.1382	1000	1000	1000	0	0	1	-360	360
66	65	0.0009	0.0101	0.1723	1000	1000	1000	0	0	1	-360	360
67	66	0.0018	0.0217	0.366	1000	1000	1000	0	0	1	-360	360
68	67	0.0009	0.0094	0.171	1000	1000	1000	0	0	1	-360	360
27	53	0.032	0.32	0.41	1000	1000	1000	0	0	1	-360	360
];




mpc.gencost = ones(16,1)*[2	1500	0	3	0.11	5	150];



%% change condition

mpc.bus(:,3)=mpc.bus(:,3)*1;
mpc.bus(:,4)=mpc.bus(:,4)*1;

mpc.gen(:,2)= mpc.gen(:,2)*1;
mpc.gen(:,3)= mpc.gen(:,3)*1;

mpc.branch(:,4)=mpc.branch(:,4);