function [results, success, raw] = ktropf_solver_eigen(om, mpopt, V0)
%KTROPF_SOLVER  Solves AC optimal power flow using KNITRO.
%
%   [RESULTS, SUCCESS, RAW] = KTROPF_SOLVER(OM, MPOPT)
%
%   Inputs are an OPF model object and a MATPOWER options struct.
%
%   Outputs are a RESULTS struct, SUCCESS flag and RAW output struct.
%
%   RESULTS is a MATPOWER case struct (mpc) with the usual baseMVA, bus
%   branch, gen, gencost fields, along with the following additional
%   fields:
%       .order      see 'help ext2int' for details of this field
%       .x          final value of optimization variables (internal order)
%       .f          final objective function value
%       .mu         shadow prices on ...
%           .var
%               .l  lower bounds on variables
%               .u  upper bounds on variables
%           .nln
%               .l  lower bounds on nonlinear constraints
%               .u  upper bounds on nonlinear constraints
%           .lin
%               .l  lower bounds on linear constraints
%               .u  upper bounds on linear constraints
%
%   SUCCESS     1 if solver converged successfully, 0 otherwise
%
%   RAW         raw output in form returned by MINOS
%       .xr     final value of optimization variables
%       .pimul  constraint multipliers
%       .info   solver specific termination code
%       .output solver specific output information
%
%   See also OPF, KTRLINK.

%   MATPOWER
%   Copyright (c) 2000-2015 by Power System Engineering Research Center (PSERC)
%   by Ray Zimmerman, PSERC Cornell
%   and Carlos E. Murillo-Sanchez, PSERC Cornell & Universidad Autonoma de Manizales
%
%   $Id: ktropf_solver.m 2644 2015-03-11 19:34:22Z ray $
%
%   This file is part of MATPOWER.
%   Covered by the 3-clause BSD License (see LICENSE file for details).
%   See http://www.pserc.cornell.edu/matpower/ for more info.

%%----- initialization -----
%% define named indices into data matrices
[PQ, PV, REF, NONE, BUS_I, BUS_TYPE, PD, QD, GS, BS, BUS_AREA, VM, ...
    VA, BASE_KV, ZONE, VMAX, VMIN, LAM_P, LAM_Q, MU_VMAX, MU_VMIN] = idx_bus;
[GEN_BUS, PG, QG, QMAX, QMIN, VG, MBASE, GEN_STATUS, PMAX, PMIN, ...
    MU_PMAX, MU_PMIN, MU_QMAX, MU_QMIN, PC1, PC2, QC1MIN, QC1MAX, ...
    QC2MIN, QC2MAX, RAMP_AGC, RAMP_10, RAMP_30, RAMP_Q, APF] = idx_gen;
[F_BUS, T_BUS, BR_R, BR_X, BR_B, RATE_A, RATE_B, RATE_C, ...
    TAP, SHIFT, BR_STATUS, PF, QF, PT, QT, MU_SF, MU_ST, ...
    ANGMIN, ANGMAX, MU_ANGMIN, MU_ANGMAX] = idx_brch;
[PW_LINEAR, POLYNOMIAL, MODEL, STARTUP, SHUTDOWN, NCOST, COST] = idx_cost;

%% options
use_ktropts_file = 1;       %% use a KNITRO options file to pass options
create_ktropts_file = 0;    %% generate a KNITRO options file on the fly

%% unpack data
mpc = get_mpc(om);
[baseMVA, bus, gen, branch, gencost] = ...
    deal(mpc.baseMVA, mpc.bus, mpc.gen, mpc.branch, mpc.gencost);
[vv, ll, nn] = get_idx(om);

%% problem dimensions
nb = size(bus, 1);          %% number of buses
ng = size(gen, 1);          %% number of gens
nl = size(branch, 1);       %% number of branches
ny = getN(om, 'var', 'y');  %% number of piece-wise linear costs

%% bounds on optimization vars
[x0, xmin, xmax] = getv(om);

%% linear constraints
[A, l, u] = linear_constraints(om);

%% split l <= A*x <= u into less than, equal to, greater than, and
%% doubly-bounded sets
ieq = find( abs(u-l) <= eps );          %% equality
igt = find( u >=  1e10 & l > -1e10 );   %% greater than, unbounded above
ilt = find( l <= -1e10 & u <  1e10 );   %% less than, unbounded below
ibx = find( (abs(u-l) > eps) & (u < 1e10) & (l > -1e10) );
Af  = [ A(ilt, :); -A(igt, :); A(ibx, :); -A(ibx, :) ];
bf  = [ u(ilt);   -l(igt);     u(ibx);    -l(ibx)];
Afeq = A(ieq, :);
bfeq = u(ieq);

%% build admittance matrices
[Ybus, Yf, Yt] = makeYbus(baseMVA, bus, branch);

%% try to select an interior initial point
if mpopt.opf.init_from_mpc ~= 1
    ll = xmin; uu = xmax;
    ll(xmin == -Inf) = -1e10;   %% replace Inf with numerical proxies
    uu(xmax ==  Inf) =  1e10;
    x0 = (ll + uu) / 2;         %% set x0 mid-way between bounds
    k = find(xmin == -Inf & xmax < Inf);    %% if only bounded above
    x0(k) = xmax(k) - 1;                    %% set just below upper bound
    k = find(xmin > -Inf & xmax == Inf);    %% if only bounded below
    x0(k) = xmin(k) + 1;                    %% set just above lower bound
    Varefs = bus(bus(:, BUS_TYPE) == REF, VA) * (pi/180);
    x0(vv.i1.Va:vv.iN.Va) = Varefs(1);  %% angles set to first reference angle
    if ny > 0
        ipwl = find(gencost(:, MODEL) == PW_LINEAR);
    %     PQ = [gen(:, PMAX); gen(:, QMAX)];
    %     c = totcost(gencost(ipwl, :), PQ(ipwl));
        c = gencost(sub2ind(size(gencost), ipwl, NCOST+2*gencost(ipwl, NCOST)));    %% largest y-value in CCV data
        x0(vv.i1.y:vv.iN.y) = max(c) + 0.1 * abs(max(c));
    %     x0(vv.i1.y:vv.iN.y) = c + 0.1 * abs(c);
    end
end

x0(1:nb)=angle(V0);
x0(nb+1:2*nb)=abs(V0);

%% find branches with flow limits
il = find(branch(:, RATE_A) ~= 0 & branch(:, RATE_A) < 1e10);
nl2 = length(il);           %% number of constrained lines

%% build Jacobian and Hessian structure
nA = size(A, 1);                %% number of original linear constraints
nx = length(x0);
f = branch(:, F_BUS);                           %% list of "from" buses
t = branch(:, T_BUS);                           %% list of "to" buses
Cf = sparse(1:nl, f, ones(nl, 1), nl, nb);      %% connection matrix for line & from buses
Ct = sparse(1:nl, t, ones(nl, 1), nl, nb);      %% connection matrix for line & to buses
Cl = Cf + Ct;
Cb = Cl' * Cl + speye(nb);
Cl2 = Cl(il, :);
Cg = sparse(gen(:, GEN_BUS), (1:ng)', 1, nb, ng);
nz = nx - 2*(nb+ng);
nxtra = nx - 2*nb;
Js = [
    Cl2     Cl2     sparse(nl2, 2*ng)               sparse(nl2,nz);
    Cl2     Cl2     sparse(nl2, 2*ng)               sparse(nl2,nz);
    Cb      Cb      Cg              sparse(nb,ng)   sparse(nb,nz);
    Cb      Cb      sparse(nb,ng)   Cg              sparse(nb,nz);
];
[f, df, d2f] = opf_costfcn(x0, om);
Hs = d2f + [
    Cb  Cb  sparse(nb,nxtra);
    Cb  Cb  sparse(nb,nxtra);
    sparse(nxtra,nx);
];

%% basic optimset options needed for ktrlink
hess_fcn = @(x, lambda)opf_hessfcn(x, lambda, 1, om, Ybus, Yf(il,:), Yt(il,:), mpopt, il);
fmoptions = optimset('GradObj', 'on', 'GradConstr', 'on', ...
                'Hessian', 'user-supplied', 'HessFcn', hess_fcn, ...
                'JacobPattern', Js, 'HessPattern', Hs );
if use_ktropts_file
    if ~isempty(mpopt.knitro.opt_fname)
        opt_fname = mpopt.knitro.opt_fname;
    elseif mpopt.knitro.opt
        opt_fname = sprintf('knitro_user_options_%d.txt', mpopt.knitro.opt);
    else
        %% create ktropts file
        ktropts.algorithm           = 1;
        ktropts.outlev              = mpopt.verbose;
        ktropts.feastol             = mpopt.opf.violation;
        ktropts.xtol                = mpopt.knitro.tol_x;
        ktropts.opttol              = mpopt.knitro.tol_f;
        if mpopt.fmincon.max_it ~= 0
            ktropts.maxit           = mpopt.fmincon.max_it;
        end
        ktropts.bar_directinterval  = 0;
        opt_fname = write_ktropts(ktropts);
        create_ktropts_file = 1;    %% make a note that I created it
    end
else
    fmoptions = optimset(fmoptions, 'Algorithm', 'interior-point', ...
        'TolCon', mpopt.opf.violation, 'TolX', mpopt.knitro.tol_x, ...
        'TolFun', mpopt.knitro.tol_f );
    if mpopt.fmincon.max_it ~= 0
        fmoptions = optimset(fmoptions, 'MaxIter', mpopt.fmincon.max_it, ...
                    'MaxFunEvals', 4 * mpopt.fmincon.max_it);
    end
    if mpopt.verbose == 0,
      fmoptions.Display = 'off';
    elseif mpopt.verbose == 1
      fmoptions.Display = 'iter';
    else
      fmoptions.Display = 'testing';
    end
    opt_fname = [];
end

%%-----  run opf  -----
f_fcn = @(x)opf_costfcn(x, om);
gh_fcn = @(x)opf_consfcn(x, om, Ybus, Yf(il,:), Yt(il,:), mpopt, il);
if have_fcn('knitromatlab')
    [x, f, info, Output, Lambda] = knitromatlab(f_fcn, x0, Af, bf, Afeq, bfeq, ...
                                    xmin, xmax, gh_fcn, [], fmoptions, opt_fname);
else
    [x, f, info, Output, Lambda] = ktrlink(f_fcn, x0, Af, bf, Afeq, bfeq, ...
                                    xmin, xmax, gh_fcn, fmoptions, opt_fname);
end
success = (info == 0);

%% delete ktropts file
if create_ktropts_file  %% ... but only if I created it
    delete(opt_fname);
end

%% update solution data
Va = x(vv.i1.Va:vv.iN.Va);
Vm = x(vv.i1.Vm:vv.iN.Vm);
Pg = x(vv.i1.Pg:vv.iN.Pg);
Qg = x(vv.i1.Qg:vv.iN.Qg);
V = Vm .* exp(1j*Va);

%%-----  calculate return values  -----
%% update voltages & generator outputs
bus(:, VA) = Va * 180/pi;
bus(:, VM) = Vm;
gen(:, PG) = Pg * baseMVA;
gen(:, QG) = Qg * baseMVA;
gen(:, VG) = Vm(gen(:, GEN_BUS));

%% compute branch flows
Sf = V(branch(:, F_BUS)) .* conj(Yf * V);  %% cplx pwr at "from" bus, p.u.
St = V(branch(:, T_BUS)) .* conj(Yt * V);  %% cplx pwr at "to" bus, p.u.
branch(:, PF) = real(Sf) * baseMVA;
branch(:, QF) = imag(Sf) * baseMVA;
branch(:, PT) = real(St) * baseMVA;
branch(:, QT) = imag(St) * baseMVA;

%% line constraint is actually on square of limit
%% so we must fix multipliers
muSf = zeros(nl, 1);
muSt = zeros(nl, 1);
if ~isempty(il)
    muSf(il) = 2 * Lambda.ineqnonlin(1:nl2)       .* branch(il, RATE_A) / baseMVA;
    muSt(il) = 2 * Lambda.ineqnonlin((1:nl2)+nl2) .* branch(il, RATE_A) / baseMVA;
end

%% update Lagrange multipliers
bus(:, MU_VMAX)  = Lambda.upper(vv.i1.Vm:vv.iN.Vm);
bus(:, MU_VMIN)  = -Lambda.lower(vv.i1.Vm:vv.iN.Vm);
gen(:, MU_PMAX)  = Lambda.upper(vv.i1.Pg:vv.iN.Pg) / baseMVA;
gen(:, MU_PMIN)  = -Lambda.lower(vv.i1.Pg:vv.iN.Pg) / baseMVA;
gen(:, MU_QMAX)  = Lambda.upper(vv.i1.Qg:vv.iN.Qg) / baseMVA;
gen(:, MU_QMIN)  = -Lambda.lower(vv.i1.Qg:vv.iN.Qg) / baseMVA;
bus(:, LAM_P)    = Lambda.eqnonlin(nn.i1.Pmis:nn.iN.Pmis) / baseMVA;
bus(:, LAM_Q)    = Lambda.eqnonlin(nn.i1.Qmis:nn.iN.Qmis) / baseMVA;
branch(:, MU_SF) = muSf / baseMVA;
branch(:, MU_ST) = muSt / baseMVA;

%% package up results
nlnN = getN(om, 'nln');
nlt = length(ilt);
ngt = length(igt);
nbx = length(ibx);

%% extract multipliers for nonlinear constraints
kl = find(Lambda.eqnonlin < 0);
ku = find(Lambda.eqnonlin > 0);
nl_mu_l = zeros(nlnN, 1);
nl_mu_u = [zeros(2*nb, 1); muSf; muSt];
nl_mu_l(kl) = -Lambda.eqnonlin(kl);
nl_mu_u(ku) =  Lambda.eqnonlin(ku);

%% extract multipliers for linear constraints
kl = find(Lambda.eqlin < 0);
ku = find(Lambda.eqlin > 0);

mu_l = zeros(size(u));
mu_l(ieq(kl)) = -Lambda.eqlin(kl);
mu_l(igt) = Lambda.ineqlin(nlt+(1:ngt));
mu_l(ibx) = Lambda.ineqlin(nlt+ngt+nbx+(1:nbx));

mu_u = zeros(size(u));
mu_u(ieq(ku)) = Lambda.eqlin(ku);
mu_u(ilt) = Lambda.ineqlin(1:nlt);
mu_u(ibx) = Lambda.ineqlin(nlt+ngt+(1:nbx));

mu = struct( ...
  'var', struct('l', -Lambda.lower, 'u', Lambda.upper), ...
  'nln', struct('l', nl_mu_l, 'u', nl_mu_u), ...
  'lin', struct('l', mu_l, 'u', mu_u) );

results = mpc;
[results.bus, results.branch, results.gen, ...
    results.om, results.x, results.mu, results.f] = ...
        deal(bus, branch, gen, om, x, mu, f);

pimul = [ ...
  results.mu.nln.l - results.mu.nln.u;
  results.mu.lin.l - results.mu.lin.u;
  -ones(ny>0, 1);
  results.mu.var.l - results.mu.var.u;
];
raw = struct('xr', x, 'pimul', pimul, 'info', info, 'output', Output);


%%-----  write_ktropts  -----
function fname = write_ktropts(ktropts)

%% generate file name
fname = sprintf('ktropts_%06d.txt', fix(1e6*rand));

%% open file
[fd, msg] = fopen(fname, 'wt');     %% write options file
if fd == -1
    error('could not create %d : %s', fname, msg);
end

%% write options
fields = fieldnames(ktropts);
for k = 1:length(fields)
    fprintf(fd, '%s %g\n', fields{k}, ktropts.(fields{k}));
end

%% close file
if fd ~= 1
    fclose(fd);
end
