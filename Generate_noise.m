function noise_seq = Generate_noise(p0,L)

noise_seq=zeros(L,1);

for i=1:L
    x=rand;
    if x<=p0
        noise_seq(i,1)=0;
    else
        noise_seq(i,1)=1;
    end
end
