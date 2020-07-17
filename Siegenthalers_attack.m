function Siegenthalers_attack()

%Feel free to change the feedback polynomials, but if this results in that the length of the registers
%is changed, you also need to alter the initial states below accordingly
feedback_polynomials={'0100000011001'; %x^13+x^10+x^9+x^2+1 for register 1
                      '000000100000001'; %x^15+x^7+1 for register 2
                      '01000000001'}; %x^11+x^2+1 for register 3
                  
initial_states={[1 0 0 0 0 1 0 1 1 0 0 0 1]; %for register 1
                [1 0 0 1 1 0 0 1 0 0 0 1 1 0 0]; %for register 2
                [0 1 1 0 1 1 1 1 0 1 0]}; %for register 3

combiner_to_use="Geffes_generator";   %define which combiner to use. Viable options are Geffes_generator, Option1, Option2 and Option3.
                                      %The 3 latter combiners are described in the report Individual project task 4
            
            
            
%Configure these values as seen fit                   
register_to_attack=1;
q=0.75; %the correlation of the lfsr we want to break, which in Geffe's generator is 0.75 for register 1 and 3
pm=0.05; pf=0; %probabilities of missing the event and false alarm, choose a value for one of them and leave the other at 0
p0=0.65; %the probability that a noisesymbol is 0, we define it to be 0.6 in this case
L=1200; %The length of our intecepted sequence

ADDITIONAL_CIPHERTEXT_FOR_TESTING=1000;





pe=1-(p0+q)+2*p0*q; %probability that sum of ciphertext and generated PN-sequence is 0

%parameters for our two distributions
mu0=0;
sig0=sqrt(L);
mu1=L*(2*pe-1);
sig1=2*sqrt(L)*sqrt(pe*(1-pe));


%calculates the threshold
        
if pm~=0 && pf==0
    z_value=abs(norminv(1-pm));

    syms T
    threshold=double(solve(abs((L*(2*pe-1)-T)/(2*sqrt(L)*sqrt(pe*(1-pe))))==z_value,T,'Real',true));
    index=min(mu0,mu1)<=threshold&threshold<=max(mu0,mu1);
    threshold=threshold(index);

    pf=1-normcdf(abs(threshold/sqrt(L)));
elseif pf~=0 && pm==0
    z_value=abs(norminv(1-pf));

    syms T
    threshold=double(solve(abs(T/sqrt(L))==z_value,T,'Real',true));
    index=min(mu0,mu1)<=threshold&threshold<=max(mu0,mu1);
    threshold=threshold(index);

    pm=1-normcdf(abs((L*(2*pe-1)-threshold)/(2*sqrt(L)*sqrt(pe*(1-pe)))));
else
    error("You can only choose to target eithrt pm or pf, not both. Pick one and set the other to 0");
end

if isempty(threshold)
    error('Was not able to determine a proper threshold due to the chosen parameters. Reasons could be too low L, unachievable Pm/Pf or P0=0.5');
end


%generates noise and ciphertext
noise_seq=Generate_noise(p0,L+ADDITIONAL_CIPHERTEXT_FOR_TESTING);
combiner=str2func(combiner_to_use);
combiner_output=combiner(initial_states,feedback_polynomials,L+ADDITIONAL_CIPHERTEXT_FOR_TESTING);
ciphertext=xor(combiner_output(1:L,1),noise_seq(1:L,1));
ciphertext_test=xor(combiner_output(1:L+ADDITIONAL_CIPHERTEXT_FOR_TESTING,1),noise_seq(1:L+ADDITIONAL_CIPHERTEXT_FOR_TESTING,1));



%testing each possible initial state
candidates=[];
candidates_counter=0;
all_attempts=de2bi(1:2^(strlength(cell2mat(feedback_polynomials(register_to_attack,:))))-1);
for i=1:size(all_attempts,1)
    a=Test_initial_state(ciphertext,all_attempts(i,:),cell2mat(feedback_polynomials(register_to_attack,:)));
    if a>=threshold&&threshold>0
        candidates_counter=candidates_counter+1;
        candidates(candidates_counter,:)=all_attempts(i,:);
     elseif a<threshold&&threshold<0
         candidates_counter=candidates_counter+1;
         candidates(candidates_counter,:)=all_attempts(i,:);
    end
end




disp('---------Results----------')
if isempty(candidates)
    error('No candidates were found. The reasons could for example be that Pe is too close to 0.5 and that L is too short');
end
fprintf('You tried to attack register %d, which has correlation %.2f\n', register_to_attack, q);
fprintf('The following parameters were used:\n');
fprintf('P0: %.2f\nL: %d\n', p0, L);

fprintf('Probabilities of false alarm and missing the event:\nPf: %.5f\nPm: %.5f\n', pf, pm);

fprintf('The calculated threshold (T) was: %.3f\n',threshold);

figure('Name','Probability distributions');
hold on
title('Probability distributions of H0 and H1');
x=[min(mu0-4*sig0,mu1-4*sig1):max(mu0+4*sig0,mu1+4*sig1)];
y0=normpdf(x,mu0,sig0);
y1=normpdf(x,mu1,sig1);
plot(x,y0,'r',x,y1,'b');
xline(threshold,'--k');
legend('P(\alpha|H_{0})','P(\alpha|H_{1})','T');
hold off




fprintf('The number of candidates found are: %d\n', candidates_counter);
if pm<0.5
    fprintf('The correct initial state for register %d is most likely one of the following, with %.2f%% certainty\n', register_to_attack, (1-pm)*100);
else
    fprintf('The correct initial state for register %d is most likely one of the following, with %.2f%% certainty\n', register_to_attack, (pm)*100);
end

if size(candidates(:,1))<1500
    for i=1:size(candidates(:,1))
        fprintf('%d: ',i);
        disp(candidates(i,:));
    end
else
    disp('...The number of candiadates is too high to print out...');
end

correct_states=cell(size(candidates(:,1),1));
index=[];

for i=1:size(candidates(:,1))    
    initial_states{register_to_attack,1}=candidates(i,:);
    combiner_output2=combiner(initial_states,feedback_polynomials,L+ADDITIONAL_CIPHERTEXT_FOR_TESTING);
    c2=xor(combiner_output2(1:L+ADDITIONAL_CIPHERTEXT_FOR_TESTING,1),noise_seq(1:L+ADDITIONAL_CIPHERTEXT_FOR_TESTING,1));
    
    if ciphertext_test==c2
        correct_states{i,1}=candidates(i,:);
        index(end+1,1)=i;
    end
end

if ~isempty(index)
    fprintf('The correct initial state was (most likely) among the candidate states and it was found to be:\n');
    disp(candidates(index(:,1),:));
else
    fprintf('The correct initial sates was not among the candidates');
end

