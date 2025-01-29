#!/sbin/sh
# thanks to REX FATHER#5241
dtc=$PWD/tools/dtc
dtp=$PWD/tools/dtp
bbox=$PWD/tools/busybox

file_getprop() { $bbox grep "^$2=" "$1" | $bbox cut -d= -f2-; }
screen=$(file_getprop settings.txt do.refresh_rate)
backup=$(file_getprop settings.txt do.backup)
dts_backup=$(file_getprop settings.txt do.dts_backup)

if [ "$backup" = "1" ]; then
	$bbox cp $PWD/tools/boot.img /sdcard/Android/boot-backup-$(date "+%Y%m%d%H%M%S").img
fi

$bbox dd if=/dev/block/bootdevice/by-name/boot of=$PWD/tools/boot.img
$PWD/tools/magiskboot unpack $PWD/tools/boot.img

$dtp -i kernel_dtb
if [ "$?" != "0" ]; then
	exit 1
fi

# decompile dtb
dtb_count=$(ls -lh kernel_dtb-* | wc -l)
board_id=$($bbox cat /proc/device-tree/qcom,board-id | $bbox xxd -p | $bbox xargs echo | $bbox sed 's/ //g' | $bbox sed 's/.\{8\}/&\n/g' | $bbox sed 's/^0\{6\}/0x/g' | $bbox sed 's/^0\{5\}/0x/g' | $bbox sed 's/^0\{4\}/0x/g' | $bbox sed 's/^0\{3\}/0x/g' | $bbox sed 's/^0\{2\}/0x/g' | $bbox sed 's/^0\{1\}x*/0x/g' | $bbox tr '\n' ' ' | $bbox sed 's/ *$/\n/g')
msm_id=$($bbox cat /proc/device-tree/qcom,msm-id | $bbox xxd -p | $bbox xargs echo | $bbox sed 's/ //g' | $bbox sed 's/.\{8\}/&\n/g' | $bbox sed 's/^0\{6\}/0x/g' | $bbox sed 's/^0\{5\}/0x/g' | $bbox sed 's/^0\{4\}/0x/g' | $bbox sed 's/^0\{3\}/0x/g' | $bbox sed 's/^0\{2\}/0x/g' | $bbox sed 's/^0\{1\}x*/0x/g' | $bbox tr '\n' ' ' | $bbox sed 's/ *$/\n/g')

i=0
while [ $i -lt $dtb_count ]; do
	$dtc -q -I dtb -O dts kernel_dtb-$i -o $PWD/tools/kernel_dtb_$i.dts
	dts_board_id=$($bbox cat $PWD/tools/kernel_dtb_$i.dts | $bbox grep qcom,board-id | $bbox sed -e 's/[\t]*qcom,board-id = <//g' | $bbox sed 's/>;//g')
	dts_msm_id=$($bbox cat $PWD/tools/kernel_dtb_$i.dts | $bbox grep qcom,msm-id | $bbox sed -e 's/[\t]*qcom,msm-id = <//g' | $bbox sed 's/>;//g')
	if [ "$dts_board_id" = "$board_id" ] && [ "$dts_msm_id" = "$msm_id" ]; then
		break
	fi
	$bbox rm -f $PWD/tools/kernel_dtb_$i.dts
	i=$((i + 1))
done
case $i in
$dtb_count)
	exit 1
;;
esac

# screen refresh rate
srr=qcom,mdss-dsi-panel-framerate
max_srr=qcom,mdss-dsi-max-refresh-rate
nsrr_=$(printf "0x%x" $screen)
$bbox sed -i "s/$srr = <[^)]*>/$srr = <$nsrr_>/g" $PWD/tools/kernel_dtb_$i.dts
$bbox sed -i "s/$max_srr = <[^)]*>/$max_srr = <$nsrr_>/g" $PWD/tools/kernel_dtb_$i.dts

# compile dts to dtb
$dtc -q -I dts -O dtb $PWD/tools/kernel_dtb_$i.dts -o kernel_dtb-$i
if [ "$dts_backup" = "1" ]; then
	$bbox cp $PWD/tools/kernel_dtb_$i.dts /sdcard/Android/backup.dts
fi

# generate new dtb
i=0
> kernel_dtb
while [ $i -lt $dtb_count ]; do
	$bbox cat kernel_dtb-$i >> kernel_dtb
	i=$((i + 1))
done

$PWD/tools/magiskboot repack $PWD/tools/boot.img
$bbox dd if=new-boot.img of=/dev/block/bootdevice/by-name/boot
$bbox rm -f kernel_dtb-*
$bbox rm -f new-boot.img