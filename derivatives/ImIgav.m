function X=ImIgav(Yg,Kg,V,expdlt_a,expdlt_v,lam)


X=Igav(Yg,Kg,V,expdlt_a,expdlt_v,lam)/2j-conj(Igav(Yg,Kg,V,expdlt_a,expdlt_v,conj(lam)))/2j;

end