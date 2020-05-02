# Contributing

## Branching model

We use the [GitHub flow](https://guides.github.com/introduction/flow/)

## Commit messages

We use [conventional commits](https://www.conventionalcommits.org/en/v1.0.0/)
Please als add an issue and the issue number as prefix to your commit message header description.

```bash
git commit -m "<type>[optional scope]: (#ticket_nr) <description>"
```

### Emojis

Feel free to add emojis to your message.

| Emoji                      | Raw Emoji Code               | Type               | Description |
|:--------------------------:|------------------------------|--------------------|-------------|
| :star:                     | `:star:`                     | `new` or `feature` | add **new feature** |
| :bug:                      | `:bug:`                      | `bug`              | fix **bug** issue |
| :ambulance:                | `:ambulance:`                | `bug`              | ciritial hotfix **bug** issue |
| :lock:                     | `:lock:`                     | `security`         | fix **security** issue |
| :chart_with_upwards_trend: | `:chart_with_upwards_trend:` | `performance`      | fix **performance** issue |
| :zap:                      | `:zap:`                      | `improvement`      | update **backwards-compatible** feature |
| :boom:                     | `:boom`                      | `breaking`         | update **backwards-incompatible** feature |
| :warning:                  | `:warning:`                  | `deprecated`       | **deprecate** feature |
| :globe_with_meridians:     | `:globe_with_meridians:`     | `i18n`             | update or fix **internationalization** |
| :wheelchair:               | `:wheelchair:`               | `a11y`             | update or fix **accessibility** |
| :lipstick:                 | `:lipstick:`                 | `update`           | update **UI/Cosmetic** |
| :up:                       | `:up:`                       | `update`           | update **other** |
| :rotating_light:           | `:rotating_light:`           | `refactor`         | remove **linter**/strict/deprecation warnings |
| :shirt:                    | `:shirt:`                    | `refactor`         | **refactoring** or code **layouting** |
| :white_check_mark:         | `:white_check_mark:`         | `test`             | add **tests** |
| :green_heart:              | `:green_heart:`              | `test`             | fix **tests** failur or **CI** building |
| :pencil:                   | `:pencil:`                   | `docs`             | update **documentation** |
| :copyright:                | `:copyright:`                | `docs`             | decide or change **license** |
| :lollipop:                 | `:lollipop:`                 | `example`          | for **example** or **demo** codes |
| :arrow_up:                 | `:arrow_up:`                 | `dependency`       | upgrade **dependencies** |
| :arrow_down:               | `:arrow_down:`               | `dependency`       | downgrade **dependencies** |
| :pushpin:                  | `:pushpin:`                  | `dependency`       | pin **dependencies** |
| :wrench:                   | `:wrench:`                   | `config`           | update **configuration** |
| :package:                  | `:package:`                  | `build`            | **packaging** or **bundling** or **building** |
| :hatching_chick:           | `:hatching_chick:`           | `release`          | **initial** commit |
| :confetti_ball:            | `:confetti_ball:`            | `release`          | release **major** version |
| :tada:                     | `:tada:`                     | `release`          | release **minor** version |
| :sparkles:                 | `:sparkles:`                 | `release`          | release **patch** version |
| :rocket:                   | `:rocket:`                   | `release`          | **deploy** to production enviroment |
| :bookmark:                 | `:bookmark:`                 | `release`          | **tagged** with version label |
| :back:                     | `:back:`                     | `revert`           | **revert** commiting |
| :construction:             | `:construction:`             | `wip`              | **WIP** commiting |
| :truck:                    | `:truck:`                    | `move`             | **move** or **rename** files, repository, ... |
| :twisted_rightwards_arrows:| `:twisted_rightwards_arrows:`| -                  | merge **conflict resolution** |
| :heavy_plus_sign:          | `:heavy_plus_sign:`          | -                  | **add** files, dependencies, ... |
| :heavy_minus_sign:         | `:heavy_minus_sign:`         | -                  | **remove** files, dependencies, ... |
| :on:                       | `:on:`                       | -                  | **enable** feature and something ... |
