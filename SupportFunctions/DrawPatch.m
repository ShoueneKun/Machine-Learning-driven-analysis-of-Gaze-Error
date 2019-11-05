function p = DrawPatch(Ax, Dim, PatchColor)

x = [Dim(1) Dim(2) Dim(2) Dim(1)];
y = [Dim(3) Dim(3) Dim(4) Dim(4)];
p = patch(x, y , PatchColor, 'EdgeColor', [0 0 0], 'LineWidth', 1, ...
    'FaceAlpha', 0.5, 'Parent', Ax);
% p.Parent = Ax;
end