# Linux Bootstrap Snippets

While there are a number of scripts here, I use only a handful frequently such as the [php-upgrade](https://github.com/pothi/snippets/raw/main/linux/php-upgrade.sh) script to upgrade the PHP version.)

Here's an overview of scripts that I used earlier.

## DigitalOcean on-demand firewall scripts.

In DigitalOcean, I used to run a very important server where most of the ports were closed except port 80 and 443. These days, it is not uncommon to open only 443. Ex: bluedart.com works only with 443 (ssl / https) and no redirect from port 80 to port 443. Anyway, I used the [DO API](https://docs.digitalocean.com/reference/api/) and [myip](https://github.com/pothi/snippets/blob/main/mac/myip) scripts to [open the firewall](https://github.com/pothi/snippets/blob/main/digitalocean/open-firewall.sh) for a quick SSH session to my IP (that is not a static IP!).

The opposite script ([closing the firewall](https://github.com/pothi/snippets/blob/main/digitalocean/close-firewall.sh)) is much easier to implement. Just check for any open SSH ports and delete all of them. This script is better placed in a scheduler so that even if you forget to close it after the work is done, the scheduler will do it for you at the predefined time. I kept it with a @daily routine.

## Linux scripts

Apart from the aforementioned php-upgrade script, I also use [common aliases and env vars](https://github.com/pothi/snippets/blob/main/linux/common-aliases-envvars) to tweak the server for better efficiency.

## Nginx

Contains configuration samples for...

- phpBB
- Sendy

## Mac

[Git pull all script](https://github.com/pothi/snippets/blob/main/mac/git-pull-all.sh) can be run on mac and linux platforms. It pulls every repo at the start of the day so that I have the updated copy of every repo. Since, I use multiple machines, I want to make sure that my repos are in sync.

I often override my cron entries without having a backup. So, [update crontab](https://github.com/pothi/snippets/blob/main/mac/update-crontab.sh) puts user's crontab under version control (in a private repo, of course).

## WordPress

[Create webp](https://github.com/pothi/snippets/blob/main/wordpress/create-webp.sh) can be used to create webp equivalents for all uploaded images. Saves a plugin on the backend! Super useful on most sites.

## SSL

The [Nginx restart](https://github.com/pothi/snippets/blob/main/ssl/nginx-restart.sh) script restarts Nginx server upon successful renewal of SSL by certbot. It can be used to restart any web server, though.

## VIM

Technically not a shell script. But, I can't live without vim and [vimrc tweaks](https://github.com/pothi/snippets/tree/main/vim) that I have been using for decades!

# Contact

You may contact me by my first name (Github username) @protonmail.com, @duck.com or @riseup.net.
