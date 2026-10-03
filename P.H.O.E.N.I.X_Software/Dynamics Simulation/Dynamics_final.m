clear
close all
clc

%% ========================================================================
% BIOINSPIRED FISH ROBOT - DYNAMICS MODEL
%
% - LaTeX labels
% - HD figure export
% - custom colors for joint angles
% - video export for 2D and 3D animations
% - positive hydrodynamic power required by the active tail
%% ========================================================================


%% ========================================================================
%% SETTINGS
%% ========================================================================
save_figs = 1;                 % 1 = save figures in HD
fig_res   = 600;               % export resolution [dpi]
out_dir   = 'figures_hd';      % folder for exported figures

save_videos   = 1;             % 1 = save animations as videos
video_fps     = 30;            % video frame rate
video_quality = 100;           % MP4 quality, from 0 to 100

if (save_figs || save_videos) && ~exist(out_dir,'dir')
    mkdir(out_dir);
end

% -------------------- MATLAB LATEX DEFAULTS ------------------------------
set(groot,'defaultTextInterpreter','latex');
set(groot,'defaultAxesTickLabelInterpreter','latex');
set(groot,'defaultLegendInterpreter','latex');

% -------------------- CUSTOM COLORS --------------------------------------
col_theta1 = [0.95 0.45 0.85];   % pink / magenta
col_theta2 = [0.30 0.82 0.98];   % cyan
col_theta3 = [0.00 0.85 0.35];   % green
col_theta4 = [0.95 0.75 0.10];   % yellow / gold

col_thrust = [0.10 0.35 0.85];
col_power  = [0.85 0.25 0.10];

col_mean = [0.20 0.20 0.20];     % grey for mean-value lines


%% ========================================================================
%% 1) GLOBAL PARAMETERS
%% ========================================================================
rho = 1000;          % [kg/m^3] water density
L_body = 0.4436;     % [m] total fish length, from nose to end of caudal fin

U = 0.70;            % [m/s] target swimming speed
St_target = 0.40;    % [-] target Strouhal number
f = 2.0;             % [Hz] actuation frequency
omega = 2*pi*f;      % [rad/s]
Tp = 1/f;            % [s] period

nPeriods = 4;
Nt = 4000;
t = linspace(0, nPeriods*Tp, Nt);

fprintf('============================================================\n');
fprintf('BIOINSPIRED FISH ROBOT - DYNAMICS MODEL\n');
fprintf('Global x starts from the nose\n');
fprintf('============================================================\n\n');


%% ========================================================================
%% 2) TAIL GEOMETRY INPUTS
%% ========================================================================
% Four moving tail links, 4-DoF articulated tail
l1 = 0.043;   % [m]
l2 = 0.036;   % [m]
l3 = 0.032;   % [m]
l4 = 0.075;   % [m]

l = [l1 l2 l3 l4];
nLinks = length(l);

L_tail = sum(l);
x_tail_start = L_body - L_tail;

fprintf('1) Tail geometry\n');
fprintf('   L_body       = %.4f m\n', L_body);
fprintf('   L_tail       = %.4f m\n', L_tail);
fprintf('   x_tail_start = %.4f m\n\n', x_tail_start);


%% ========================================================================
%% 3) PRESCRIBED JOINT-ANGLE LAWS
%% ========================================================================
alpha = [0.56 0.67 0.78 1.00];

DeltaPsi_deg = -30;
DeltaPsi = deg2rad(DeltaPsi_deg);

psi = (0:nLinks-1) * DeltaPsi;

fprintf('2) Prescribed joint-angle laws\n');
fprintf('   alpha = [%.2f %.2f %.2f %.2f]\n', alpha);
fprintf('   psi   = [%.1f %.1f %.1f %.1f] deg\n\n', rad2deg(psi));


%% ========================================================================
%% 4) TARGET OPERATING CONDITION FROM STROUHAL
%% ========================================================================
A_target = St_target * U / (2*f);

fprintf('3) Target operating condition\n');
fprintf('   U          = %.3f m/s\n', U);
fprintf('   St_target  = %.3f\n', St_target);
fprintf('   f          = %.3f Hz\n', f);
fprintf('   A_target   = %.5f m = %.1f mm\n\n', A_target, 1000*A_target);


%% ========================================================================
%% 5) AMPLITUDE MATCHING
%% ========================================================================
% The Strouhal number defines the target tail-tip amplitude:
%
%   A_target = St_target * U / (2*f)
%
% However, Strouhal does not directly define the individual joint amplitudes.
% The relative amplitude distribution is defined by alpha:
%
%   A_i = alpha_i * Theta_max
%
% Here Theta_max is found numerically so that the realized tail-tip
% amplitude matches A_target.

tailTipAmplitude = @(Theta_max) compute_tail_tip_amplitude( ...
    alpha, Theta_max, omega, t, psi, l, x_tail_start);

Theta_low = 0;
Theta_high = deg2rad(5);

while tailTipAmplitude(Theta_high) < A_target
    Theta_high = 1.5 * Theta_high;

    if Theta_high > deg2rad(80)
        error('Target tail-tip amplitude not reached before 80 deg. Check St, U, f, alpha or geometry.');
    end
end

Theta_max = fzero(@(Theta) tailTipAmplitude(Theta) - A_target, ...
                  [Theta_low, Theta_high]);

A_i = alpha * Theta_max;

fprintf('4) Amplitude matching\n');
fprintf('   Target tail-tip amplitude A_target = %.5f m = %.1f mm\n', A_target, 1000*A_target);
fprintf('   Theta_max = %.5f rad = %.2f deg\n', Theta_max, rad2deg(Theta_max));
fprintf('   Joint amplitudes A_i = [%.2f %.2f %.2f %.2f] deg\n\n', rad2deg(A_i));


%% ========================================================================
%% 6) FINAL JOINT KINEMATICS
%% ========================================================================
theta = zeros(nLinks, Nt);
for i = 1:nLinks
    theta(i,:) = A_i(i) .* sin(omega*t + psi(i));
end

phi = zeros(nLinks, Nt);
phi(1,:) = theta(1,:);

for i = 2:nLinks
    phi(i,:) = phi(i-1,:) + theta(i,:);
end

x = zeros(nLinks, Nt);
z = zeros(nLinks, Nt);

for k = 1:Nt
    x_prev = x_tail_start;
    z_prev = 0;

    for i = 1:nLinks
        x(i,k) = x_prev + l(i)*cos(phi(i,k));
        z(i,k) = z_prev + l(i)*sin(phi(i,k));

        x_prev = x(i,k);
        z_prev = z(i,k);
    end
end

z_tip = z(end,:);
A_tip_real = max(abs(z_tip));
St_real = 2*f*A_tip_real/U;

fprintf('5) Final articulated-tail kinematics\n');
fprintf('   Tail-tip realized amplitude = %.5f m = %.1f mm\n', A_tip_real, 1000*A_tip_real);
fprintf('   Realized Strouhal = %.4f\n\n', St_real);


%% ========================================================================
%% 7) CONTINUOUS CENTERLINE h(x,t) ON THE GLOBAL x-DOMAIN OF THE TAIL
%% ========================================================================
% IMPORTANT:
% x is the global undeformed axial coordinate, measured from the nose.
% The centerline is reconstructed on the active tail domain only.

Nx = 300;
x_grid = linspace(x_tail_start, L_body, Nx);   % global x from nose
h = zeros(Nx, Nt);

% Nominal axial coordinates of the joints along the undeformed tail
x_nodes = x_tail_start + [0, cumsum(l)];

for k = 1:Nt
    z_nodes = [0, z(1,k), z(2,k), z(3,k), z(4,k)];

    for j = 1:nLinks
        idx = (x_grid >= x_nodes(j)) & (x_grid <= x_nodes(j+1));

        xj  = x_nodes(j);
        xj1 = x_nodes(j+1);
        zj  = z_nodes(j);
        zj1 = z_nodes(j+1);

        h(idx,k) = zj + ((zj1 - zj)/(xj1 - xj)) .* (x_grid(idx) - xj);
    end
end

fprintf('6) Continuous centerline h(x,t) built on global x-grid\n\n');


%% ========================================================================
%% 8) KINEMATIC DERIVATIVES ON THE WHOLE TAIL DOMAIN
%% ========================================================================
% Spatial derivative dh/dx
dhdx = zeros(Nx, Nt);
for k = 1:Nt
    dhdx(:,k) = gradient(h(:,k), x_grid);
end

% Time derivative dh/dt
dhdt = zeros(Nx, Nt);
for i = 1:Nx
    dhdt(i,:) = gradient(h(i,:), t);
end

% Tail-end values
dhdx_L = dhdx(end,:);
dhdt_L = dhdt(end,:);

fprintf('7) Distributed derivatives computed\n\n');


%% ========================================================================
%% 9) ELLIPTICAL EQUIVALENT AREA FUNCTION A(x) ON THE TAIL DOMAIN
%% ========================================================================
% -------------------- x positions, from nose -----------------------------
x_body = [x_tail_start, 0.27, 0.30, 0.32, 0.35, 0.375];
x_fin  = [0.40, 0.405, 0.41, 0.415, 0.42, 0.425, 0.43, 0.435, L_body];
x_cad  = [x_body, x_fin];

% -------------------- semi-height a(x) ----------------------------------
a_body = [0.032, 0.02996, 0.02375, 0.01913, 0.0119, 0.00525];

a_fin = [ ...
    0.035, ...
    0.0404, ...
    0.046, ...
    0.0516, ...
    0.056, ...
    0.0609, ...
    0.065, ...
    0.069, ...
    0.070];

a_cad = [a_body, a_fin];

% -------------------- semi-width b(x) -----------------------------------
b_body = [0.02563, 0.02462, 0.02121, 0.01583, 0.01164, 0.0039];

c_fin = [ ...
    0.027, ...
    0.038, ...
    0.045, ...
    0.052, ...
    0.058, ...
    0.063, ...
    0.068, ...
    0.072, ...
    0.07469];

b_fin = c_fin / 2;
b_cad = [b_body, b_fin];

% -------------------- interpolation functions ---------------------------
a_func = @(xq) interp1(x_cad, a_cad, xq, 'pchip', 'extrap');
b_func = @(xq) interp1(x_cad, b_cad, xq, 'pchip', 'extrap');

% -------------------- equivalent area -----------------------------------
A_func = @(xq) pi .* a_func(xq) .* b_func(xq);

% Distributed area on the x-grid
A_x = A_func(x_grid).';
A_L = A_func(L_body);

fprintf('8) Hydrodynamic area model\n');
fprintf('   Tail-end equivalent area A(L) = %.6e m^2\n\n', A_L);


%% ========================================================================
%% 10) INSTANTANEOUS HYDRODYNAMICS, DISTRIBUTED MODEL USING A(x)
%% ========================================================================
% Lateral velocity:
% v_z(x,t) = dh/dt + U dh/dx
vz = dhdt + U .* dhdx;

% Time derivative of v_z
dvzdt = zeros(Nx, Nt);
for i = 1:Nx
    dvzdt(i,:) = gradient(vz(i,:), t);
end

% Spatial derivative of v_z
dvzdx = zeros(Nx, Nt);
for k = 1:Nt
    dvzdx(:,k) = gradient(vz(:,k), x_grid);
end

% Derivative of A(x)
dAdx = gradient(A_x, x_grid).';
dAdx = dAdx(:);

% Local lift-force density:
% ell(x,t) = rho*A*dvz/dt + rho*U*dA/dx*vz + rho*U*A*dvz/dx
ell = zeros(Nx, Nt);

for k = 1:Nt
    ell(:,k) = rho .* A_x .* dvzdt(:,k) ...
             + rho .* U .* dAdx .* vz(:,k) ...
             + rho .* U .* A_x .* dvzdx(:,k);
end

% Instantaneous thrust:
% T(t) = - integral ell(x,t) * dh/dx dx
T_inst = zeros(1, Nt);
for k = 1:Nt
    T_inst(k) = -trapz(x_grid, ell(:,k) .* dhdx(:,k));
end

% Instantaneous signed hydrodynamic power:
% Sign depends on the force convention.
P_inst_signed = zeros(1, Nt);
for k = 1:Nt
    P_inst_signed(k) = -trapz(x_grid, ell(:,k) .* dhdt(:,k));
end

% Positive hydrodynamic power required by the active tail.
% This is the quantity plotted and used for peak power.
P_tail_inst = -P_inst_signed;

fprintf('9) Instantaneous distributed hydrodynamics computed\n\n');


%% ========================================================================
%% 11) MEAN VALUES, REDUCED BOUNDARY FORMULAS AT x = L
%% ========================================================================
idx_last = t >= (nPeriods-1)*Tp;

T_red = 0.5 * rho * A_L .* (dhdt_L.^2 - U^2 .* dhdx_L.^2);
P_red = rho * U * A_L .* (dhdt_L .* (dhdt_L + U .* dhdx_L));

T_mean = mean(T_red(idx_last));
P_mean = mean(P_red(idx_last));

if abs(P_mean) > 1e-12
    eta = (T_mean * U) / P_mean;
else
    eta = 0;
end

fprintf('10) Mean performance, boundary formulas\n');
fprintf('   Mean thrust T_mean = %.6f N\n', T_mean);
fprintf('   Mean power  P_mean = %.6f W\n', P_mean);
fprintf('   Efficiency  eta    = %.4f\n\n', eta);


%% ========================================================================
%% 12) MOTOR REQUIREMENTS, INCLUDING SILICONE LOSSES
%% ========================================================================
% Peak hydrodynamic quantities.
% P_max is computed from positive required tail power.
P_max = max(P_tail_inst(idx_last));   % [W]
T_max = max(abs(T_inst(idx_last)));   % [N]

RPM = 60 * f;
tau_max = P_max / omega;              % [N*m]

% Loss factor for silicone skin / structural losses
K_loss = 1.20;

% Safety factor
SF = 1.20;

tau_motor = SF * K_loss * tau_max;
P_motor   = SF * K_loss * P_max;

fprintf('11) Motor requirements, including silicone losses\n');
fprintf('   Frequency            = %.2f Hz (%.1f RPM)\n', f, RPM);
fprintf('   Peak thrust          = %.6f N\n', T_max);
fprintf('   Hydrodynamic P_max   = %.6f W\n', P_max);
fprintf('   Loss factor K_loss   = %.2f\n', K_loss);
fprintf('   Peak torque, fluid   = %.6f N*m\n', tau_max);
fprintf('   Recommended torque   = %.6f N*m, SF = %.1f, K = %.1f\n', tau_motor, SF, K_loss);
fprintf('   Recommended power    = %.6f W, SF = %.1f, K = %.1f\n\n', P_motor, SF, K_loss);


%% ========================================================================
%% 13) PLOTS
%% ========================================================================

% ------------------ Joint angles -----------------------------------------
fig1 = figure('Name','Joint Angles','Color','w','Position',[100 100 1000 550]);

plot(t, rad2deg(theta(1,:)), 'LineWidth', 2.0, 'Color', col_theta1); hold on
plot(t, rad2deg(theta(2,:)), 'LineWidth', 2.0, 'Color', col_theta2);
plot(t, rad2deg(theta(3,:)), 'LineWidth', 2.0, 'Color', col_theta3);
plot(t, rad2deg(theta(4,:)), 'LineWidth', 2.0, 'Color', col_theta4);

grid on
box on
set(gca, 'FontSize', 14);

xlabel('$t\,[\mathrm{s}]$');
ylabel('$\vartheta_i\,[^\circ]$');

legend({'$\vartheta_1$','$\vartheta_2$','$\vartheta_3$','$\vartheta_4$'}, ...
    'Location','best');

title('Joint kinematics');

if save_figs
    exportgraphics(fig1, fullfile(out_dir,'01_joint_angles.png'), 'Resolution', fig_res);
end


% ------------------ Tail tip motion --------------------------------------
fig2 = figure('Name','Tail Tip Motion','Color','w','Position',[120 120 1000 550]);

plot(t, z_tip, 'LineWidth', 2.0, 'Color', [0.15 0.35 0.85]);
hold on
yline(A_target, '--', 'LineWidth', 1.3, 'Color', [0.35 0.35 0.35]);
yline(-A_target, '--', 'LineWidth', 1.3, 'Color', [0.35 0.35 0.35]);
hold off

grid on
box on
set(gca, 'FontSize', 14);

xlabel('$t\,[\mathrm{s}]$');
ylabel('$z_{\mathrm{tip}}(t)\,[\mathrm{m}]$');
title('Tail-tip motion');

legend({'$z_{\mathrm{tip}}(t)$','$\pm A_{\mathrm{target}}$'}, ...
    'Location','best');

if save_figs
    exportgraphics(fig2, fullfile(out_dir,'02_tail_tip_motion.png'), 'Resolution', fig_res);
end


% ------------------ Centerline snapshots ---------------------------------
fig3 = figure('Name','Centerline Snapshots','Color','w','Position',[140 140 1000 550]);

snap_idx = round(linspace(1, Nt, 6));
plot(x_grid, h(:,snap_idx), 'LineWidth', 1.8);

grid on
box on
set(gca, 'FontSize', 14);

xlabel('$x$ (from nose) $[\mathrm{m}]$');
ylabel('$h(x,t)\,[\mathrm{m}]$');
title('Centerline deformation');

leg_snap = cell(1,numel(snap_idx));
for ii = 1:numel(snap_idx)
    leg_snap{ii} = sprintf('$t = %.2f\\,\\mathrm{s}$', t(snap_idx(ii)));
end
legend(leg_snap, 'Location', 'best');

if save_figs
    exportgraphics(fig3, fullfile(out_dir,'03_centerline_snapshots.png'), 'Resolution', fig_res);
end


% ------------------ Elliptical geometry ----------------------------------
x_plot_geom = linspace(x_tail_start, L_body, 500);
a_plot = a_func(x_plot_geom);
b_plot = b_func(x_plot_geom);
A_plot = A_func(x_plot_geom);

fig4 = figure('Name','Equivalent Elliptical Geometry','Color','w','Position',[160 160 1000 900]);

subplot(3,1,1)
plot(x_plot_geom, a_plot, 'LineWidth', 2.2, 'Color', [0.10 0.35 0.85]); hold on
plot(x_cad, a_cad, 'o', 'MarkerFaceColor', [0.90 0.15 0.15], ...
    'MarkerEdgeColor', [0.90 0.15 0.15], 'MarkerSize', 6);
grid on
box on
set(gca, 'FontSize', 13);
ylabel('$a(x)\,[\mathrm{m}]$');
title('Semi-height');

subplot(3,1,2)
plot(x_plot_geom, b_plot, 'LineWidth', 2.2, 'Color', [0.80 0.10 0.60]); hold on
plot(x_cad, b_cad, 'o', 'MarkerFaceColor', 'k', ...
    'MarkerEdgeColor', 'k', 'MarkerSize', 6);
grid on
box on
set(gca, 'FontSize', 13);
ylabel('$b(x)\,[\mathrm{m}]$');
title('Semi-width');

subplot(3,1,3)
plot(x_plot_geom, A_plot, 'LineWidth', 2.2, 'Color', [0.00 0.60 0.25]);
grid on
box on
set(gca, 'FontSize', 13);
xlabel('$x$ (from nose) $[\mathrm{m}]$');
ylabel('$A(x)\,[\mathrm{m}^2]$');
title('Equivalent area');

if save_figs
    exportgraphics(fig4, fullfile(out_dir,'04_equivalent_geometry.png'), 'Resolution', fig_res);
end


% ------------------ Instantaneous thrust and positive tail power ----------
fig5 = figure('Name','Hydrodynamic Loads','Color','w','Position',[180 180 1200 850]);

% Common settings for readable labels
x_text = t(end) - 0.03*(t(end)-t(1));

% ------------------ Thrust plot ------------------------------------------
subplot(2,1,1)

plot(t, T_inst, 'LineWidth', 2.0, 'Color', col_thrust);
hold on

yline(T_mean, '--', ...
    'LineWidth', 1.6, ...
    'Color', col_mean);

% Put the mean value in a readable text box
yl = ylim;
y_text_T = T_mean + 0.12*(yl(2)-yl(1));

text(x_text, y_text_T, ...
    sprintf('$T_{\\mathrm{mean}} = %.2f\\,\\mathrm{N}$', T_mean), ...
    'Interpreter','latex', ...
    'FontSize', 14, ...
    'HorizontalAlignment','right', ...
    'VerticalAlignment','bottom', ...
    'BackgroundColor','w', ...
    'EdgeColor',[0.65 0.65 0.65], ...
    'Margin',5);

hold off

grid on
box on
set(gca, 'FontSize', 14);

xlabel('$t\,[\mathrm{s}]$');
ylabel('$T(t)\,[\mathrm{N}]$');
title('Instantaneous tail-generated thrust');


% ------------------ Power plot -------------------------------------------
subplot(2,1,2)

plot(t, P_tail_inst, 'LineWidth', 2.0, 'Color', col_power);
hold on

yline(P_mean, '--', ...
    'LineWidth', 1.6, ...
    'Color', col_mean);

% Put the mean value in a readable text box
yl = ylim;
y_text_P = P_mean + 0.12*(yl(2)-yl(1));

text(x_text, y_text_P, ...
    sprintf('$P_{\\mathrm{mean}} = %.2f\\,\\mathrm{W}$', P_mean), ...
    'Interpreter','latex', ...
    'FontSize', 14, ...
    'HorizontalAlignment','right', ...
    'VerticalAlignment','bottom', ...
    'BackgroundColor','w', ...
    'EdgeColor',[0.65 0.65 0.65], ...
    'Margin',5);

hold off

grid on
box on
set(gca, 'FontSize', 14);

xlabel('$t\,[\mathrm{s}]$');
ylabel('$P_{\mathrm{tail}}(t)\,[\mathrm{W}]$');
title('Hydrodynamic power required by the active tail');


if save_figs
    exportgraphics(fig5, fullfile(out_dir,'05_hydrodynamic_loads.png'), 'Resolution', fig_res);
end


%% ========================================================================
%% 14) 3D STATIC GEOMETRY
%% ========================================================================
Nx_plot = 80;
Ntheta = 40;

x_plot = linspace(x_tail_start, L_body, Nx_plot);
theta_ellipse = linspace(0, 2*pi, Ntheta);

[Xsurf, Ysurf, Zsurf] = deal(zeros(Ntheta, Nx_plot));

for i = 1:Nx_plot
    xi = x_plot(i);

    a = a_func(xi);   % height
    b = b_func(xi);   % width

    Ysurf(:,i) = b * cos(theta_ellipse);   % lateral
    Zsurf(:,i) = a * sin(theta_ellipse);   % vertical
    Xsurf(:,i) = xi;
end

fig6 = figure('Name','3D Equivalent Tail Static','Color','w','Position',[200 200 1000 700]);
surf(Xsurf, Ysurf, Zsurf, 'EdgeColor', 'none');

shading interp
colormap turbo
axis equal
grid on
box on
view(45,25)
camlight
lighting gouraud
set(gca, 'FontSize', 14);

xlabel('$x$ (from nose) $[\mathrm{m}]$');
ylabel('$z$ (lateral) $[\mathrm{m}]$');
zlabel('$y$ (height) $[\mathrm{m}]$');
title('Equivalent elliptical tail geometry');

if save_figs
    exportgraphics(fig6, fullfile(out_dir,'06_3D_static_geometry.png'), 'Resolution', fig_res);
end


%% ========================================================================
%% 15) 2D ANIMATION + VIDEO EXPORT
%% ========================================================================
fig7 = figure('Name','2D Tail Animation','Color','w','Position',[220 220 1200 650]);

zmax = 1.2 * max(abs(h(:)));

if save_videos
    video2D_path = fullfile(out_dir, '07_2D_tail_animation.mp4');

    v2D = VideoWriter(video2D_path, 'MPEG-4');
    v2D.FrameRate = video_fps;
    v2D.Quality = video_quality;
    open(v2D);
end

for k = 1:20:Nt

    plot(x_grid, h(:,k), 'LineWidth', 2.8, 'Color', [0.10 0.35 0.85]);
    hold on
    plot([x_tail_start L_body], [0 0], '--', ...
        'Color', [0.25 0.25 0.25], 'LineWidth', 1.3);
    hold off

    grid on
    box on
    set(gca, 'FontSize', 14);

    xlabel('$x\,[\mathrm{m}]$');
    ylabel('$h(x,t)\,[\mathrm{m}]$');
    title(sprintf('Tail centerline reconstruction -- $t = %.2f\\,\\mathrm{s}$', t(k)));

    axis([x_tail_start L_body -zmax zmax])

    drawnow;

    if save_videos
        frame = getframe(fig7);
        writeVideo(v2D, frame);
    end
end

if save_videos
    close(v2D);
    fprintf('2D animation video saved as: %s\n', video2D_path);
end

if save_figs
    exportgraphics(fig7, fullfile(out_dir,'07_2D_tail_animation_frame.png'), ...
        'Resolution', fig_res);
end


%% ========================================================================
%% 16) 3D ANIMATION + VIDEO EXPORT
%% ========================================================================
fig8 = figure('Name','3D Swimming Tail','Color','w','Position',[240 240 1200 750]);

Nx_plot = 80;
Ntheta = 30;

x_plot = linspace(x_tail_start, L_body, Nx_plot);
theta_ellipse = linspace(0, 2*pi, Ntheta);

[Xsurf, Ysurf, Zsurf] = deal(zeros(Ntheta, Nx_plot));

motion_max = 1.3 * max(abs(h(:)));
geom_max   = 1.3 * max(a_cad);

if save_videos
    video3D_path = fullfile(out_dir, '08_3D_swimming_tail.mp4');

    v3D = VideoWriter(video3D_path, 'MPEG-4');
    v3D.FrameRate = video_fps;
    v3D.Quality = video_quality;
    open(v3D);
end

for k = 1:20:Nt

    for i = 1:Nx_plot
        xi = x_plot(i);

        a = a_func(xi);
        b = b_func(xi);

        h_xt = interp1(x_grid, h(:,k), xi);

        Ysurf(:,i) = b * cos(theta_ellipse) + h_xt;  % lateral motion
        Zsurf(:,i) = a * sin(theta_ellipse);         % vertical geometry
        Xsurf(:,i) = xi;
    end

    if k == 1
        hSurf = surf(Xsurf, Ysurf, Zsurf, 'EdgeColor', 'none');
        shading interp
        colormap turbo
        camlight
        lighting gouraud
    else
        set(hSurf, 'XData', Xsurf, 'YData', Ysurf, 'ZData', Zsurf);
    end

    axis equal
    xlim([x_tail_start L_body])
    ylim([-motion_max motion_max])
    zlim([-geom_max geom_max])

    view(45,25)
    grid on
    box on
    set(gca, 'FontSize', 14);

    xlabel('$x\,[\mathrm{m}]$');
    ylabel('$z$ (lateral motion) $[\mathrm{m}]$');
    zlabel('$y$ (height) $[\mathrm{m}]$');
    title(sprintf('3D swimming tail geometry -- $t = %.2f\\,\\mathrm{s}$', t(k)));

    drawnow;

    if save_videos
        frame = getframe(fig8);
        writeVideo(v3D, frame);
    end
end

if save_videos
    close(v3D);
    fprintf('3D animation video saved as: %s\n', video3D_path);
end

if save_figs
    exportgraphics(fig8, fullfile(out_dir,'08_3D_swimming_tail_frame.png'), ...
        'Resolution', fig_res);
end


%% ========================================================================
%% 17) RESULTS STRUCT
%% ========================================================================
results = struct();

results.rho = rho;
results.L_body = L_body;
results.L_tail = L_tail;
results.x_tail_start = x_tail_start;

results.U = U;
results.St_target = St_target;
results.St_real = St_real;
results.f = f;
results.omega = omega;
results.Tp = Tp;

results.l = l;
results.alpha = alpha;
results.psi = psi;
results.A_target = A_target;
results.Theta_max = Theta_max;
results.A_i = A_i;

results.theta = theta;
results.phi = phi;
results.x = x;
results.z = z;
results.z_tip = z_tip;
results.A_tip_real = A_tip_real;

results.x_grid = x_grid;
results.h = h;
results.dhdx = dhdx;
results.dhdt = dhdt;
results.dhdx_L = dhdx_L;
results.dhdt_L = dhdt_L;

results.x_cad = x_cad;
results.a_cad = a_cad;
results.b_cad = b_cad;
results.A_x = A_x;
results.A_L = A_L;

results.vz = vz;
results.ell = ell;

results.T_inst = T_inst;
results.P_inst_signed = P_inst_signed;
results.P_tail_inst = P_tail_inst;

results.T_red = T_red;
results.P_red = P_red;

results.T_mean = T_mean;
results.P_mean = P_mean;
results.eta = eta;

results.P_max = P_max;
results.T_max = T_max;
results.tau_max = tau_max;
results.tau_motor = tau_motor;
results.P_motor = P_motor;

results.colors.theta1 = col_theta1;
results.colors.theta2 = col_theta2;
results.colors.theta3 = col_theta3;
results.colors.theta4 = col_theta4;

disp('Results saved in struct: results');

if save_figs || save_videos
    fprintf('\nFiles saved in folder: %s\n', out_dir);
end


%% ========================================================================
%% LOCAL FUNCTION
%% ========================================================================
function A_tip = compute_tail_tip_amplitude(alpha, Theta_max, omega, t, psi, l, x_tail_start)

    nLinks = length(l);
    Nt = length(t);

    theta = zeros(nLinks, Nt);

    for i = 1:nLinks
        theta(i,:) = alpha(i) * Theta_max .* sin(omega*t + psi(i));
    end

    phi = zeros(nLinks, Nt);
    phi(1,:) = theta(1,:);

    for i = 2:nLinks
        phi(i,:) = phi(i-1,:) + theta(i,:);
    end

    z = zeros(nLinks, Nt);

    for k = 1:Nt
        x_prev = x_tail_start;
        z_prev = 0;

        for i = 1:nLinks
            x_i = x_prev + l(i)*cos(phi(i,k));
            z_i = z_prev + l(i)*sin(phi(i,k));

            z(i,k) = z_i;

            x_prev = x_i;
            z_prev = z_i;
        end
    end

    z_tip = z(end,:);
    A_tip = max(abs(z_tip));

end
