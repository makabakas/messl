function marginals = mrfGridLbp(dataPot, compatPot, nIter, doPlot)

% Sum-product loopy belief propagation on a grid Markov random field
%
% marginals = mrfGridLbp(dataPot, compatPot, nIter)
%
% Each point in the grid is connected to its 4 manhattan neighbors.  All
% inputs should be in linear units, not log.  Edge nodes are not updated.
%
% Inputs:
%   dataPot    data potential, FxTxI matrix (freq x time x state)
%   compatPot  compatibility potential, IxIx4 for 4-neighbors, 
%   nIter      number of iterations of loopy BP
%
% Outputs:
%   marginals  final marginal probabilities after nIter iterations, FxTxI

% BP: m_{ij}(x_j) = \sum_{x_i} \phi_i(x_i) \psi_{ij}(x_i, x_j) \prod_{k \in N(i) \ j} m_{ki}(x_i)
% In my case, "messages" is organized by receiver, so for message
% m_{ki}(x_i), i is the first two dimension of messages and k is the fourth
% dimension.  So I need to be clever about where to put the output
% messages.
%
% Neighbors:     1      [(-1,0), (0,1), (1,0), (0,-1)]
%             4  X  2   df = [-1  0  1  0] = mod(n,  2).*(n-2)
%                3      dt = [ 0  1  0 -1] = mod(n+1,2).*(3-n)

if ~exist('doPlot', 'var') || isempty(doPlot), doPlot = 0; end

[F T I] = size(dataPot);
nNeigh = 4;
messages = 1/I * ones([F T I nNeigh]);

for iter = 1:nIter
    for neigh = 1:nNeigh
        incomingMsgs = prod(messages, 4);
        incomingMsgs = incomingMsgs ./ messages(:,:,:,neigh);

        % Outgoing messages are computed at point (f,t)
        msg = zeros([F T I]);
        for i1 = 1:I
            for i2 = 1:I
                msg(:,:,i1) = msg(:,:,i1) + dataPot(:,:,i2) .* incomingMsgs(:,:,i2) .* compatPot(i1,i2,neigh);
            end
        end
        msg = bsxfun(@rdivide, msg, sum(msg,3) + 1e-9);
        
        % Incoming messages are put at (f+df,t+dt)
        df = mod(neigh,   2).*(neigh - 2);  % [-1  0  1  0];
        dt = mod(neigh+1, 2).*(3 - neigh);  % [ 0  1  0 -1];
        msg = msg(max(1,1-df):min(F,F-df), max(1,1-dt):min(T,T-dt), :);
        messages(max(1,1+df):min(F,F+df), max(1,1+dt):min(T,T+dt), :, neigh) = msg;
    end
    
    if doPlot
        marginals = dataPot .* prod(messages, 4);
        marginals = bsxfun(@rdivide, marginals, sum(marginals, 3) + 1e-9);
        subplots({marginals(:,:,1), dataPot(:,:,1)});
        drawnow
    end
end

marginals = dataPot .* prod(messages, 4);
marginals = bsxfun(@rdivide, marginals, sum(marginals, 3) + 1e-9);