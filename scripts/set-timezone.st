set user SystemUser pass swordfish gems $APPLICATION_NAME
display oops

iferror where

login

run
| osTZ |
System beginTransaction.
osTZ := TimeZone fromOS.
osTZ installAsCurrentTimeZone.
TimeZone default: osTZ.
TimeZoneInfo default: osTZ.
System commitTransaction.
%
