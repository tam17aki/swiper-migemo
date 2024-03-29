# swiper-migemo
Use ivy/counsel/swiper with migemo.

## Motivation
In the past, many people used avy-migemo to support migemo in swiper, ivy and
counsel. However, avy-migemo has not been maintained for a long time, and
many attempts have been made to achieve migemo support without using
avy-migemo. I decided to write a new minor-mode to make those commands with
ivy-based interface compatible with migemo.

## Basic Usage
### `global-swiper-migemo-mode`
Activate `global-swiper-migemo-mode`: add following code to your init file.

```el
(require 'swiper-migemo)
(global-swiper-migemo-mode +1)
```
In default setting, you can use `swiper` and `swiper-isearch` with migemo.

### `swiper-migemo-mode`
Alternatively, you can activate `swiper-migemo-mode` via "M-x swiper-migemo-mode".
You can also toggle this minor-mode by invoking `swiper-migemo-mode` again. 
In this case,  the minor-mode will be activated in buffer-local and never use `global-swiper-migemo-mode` in the init file.

## Customization
You can customize `swiper-migemo-enable-command` which is a list of commands
to use migemo-mode.

For example, If you want to use `counsel-recentf` with migemo, add following code in the
init file:

```el
(add-to-list 'swiper-migemo-enable-command 'counsel-recentf)
```

Furthermore, if you want to use `counsel-rg` with migemo, add following code
in the init file:

```el
(add-to-list 'swiper-migemo-enable-command 'counsel-rg)
(setq migemo-options '("--quiet" "--nonewline" "--emacs"))
(migemo-kill)
(migemo-init)
```

Note: the above settings must be evaluated before the activataion of this
minor-mode. That is,

```el
(require 'swiper-migemo)
(add-to-list 'swiper-migemo-enable-command 'counsel-recentf)
(add-to-list 'swiper-migemo-enable-command 'counsel-rg)
(setq migemo-options '("--quiet" "--nonewline" "--emacs"))
(migemo-kill)
(migemo-init)
(global-swiper-migemo-mode +1)
```
