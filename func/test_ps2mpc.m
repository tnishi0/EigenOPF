
%========================================================================
% system='test_system_3gen';

%========================================================================
% system='test_system_10gen';
% 
%========================================================================
system='test_system_50gen';

%========================================================================
% system='test_system_505gen';

%========================================================================
% system='test_system_1445gen';

%========================================================================

loadmode=0;
mpc = load_system(system, loadmode);
ps = mpc2ps(mpc);


mpc1=ps2mpc(ps);
norm(full(makeYbus(mpc1.baseMVA, mpc1.bus, mpc1.branch)-ps.Y),inf)