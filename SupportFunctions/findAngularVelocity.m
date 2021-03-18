function out = findAngularVelocity(t, in)
%% findAngularVelocity
% Following the central difference algorithm

% out = diff(180*in(:)/pi)./diff(t(:));
% out = [0; out(:)]; % Add a zero to keep the number of samples same.

% out = zeros(length(in), 1);
% out(1) = 0;
% A = sin(in(2:end)).*cos(in(1:end-1));
% B = sin(in(1:end-1)).*cos(in(2:end));
% out(2:end) = (180/pi)*(A(:) - B(:))./diff(t(:));

A = sin(in(3:end)).*cos(in(1:end-2));
B = sin(in(1:end-2)).*cos(in(3:end));
out = (180/pi)*(A(:) - B(:))./(t(3:end) - t(1:end-2));
out = [out(1); out; out(end)];
out(out > 700) = 700;
out(out < -700) = -700;
if sum(isnan(out))
    keyboard
end
end