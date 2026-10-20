# Copyright (c) 2026 SboMusic
# SPDX-License-Identifier: PolyForm-Noncommercial-1.0.0
extends RefCounted
static func icon(slot: int) -> ImageTexture:
	var shapes := [
		'<circle cx="47" cy="43" r="22" fill="url(#gold)"/><path d="M47 7v20m-8-11h16" stroke="#fff0ae" stroke-width="6"/><path d="M26 39q20-18 40 0" fill="none" stroke="#fff4c8" stroke-width="3"/>',
		'<path d="M12 48L64 15 78 22 70 38 21 57Z" fill="url(#metal)"/><path d="M64 15l14 7-8 16" fill="#ec7252"/><path d="M17 45l-9-2 3 16 14-2" fill="#63d6ba"/><circle cx="78" cy="51" r="12" fill="none" stroke="#a5f9dd" stroke-width="3"/><path d="M78 35v32m-16-16h32" stroke="#a5f9dd" stroke-width="2"/>',
		'<path d="M10 42L65 17 78 25 67 40 16 54Z" fill="url(#metal)"/><path d="M65 17l13 8-11 15" fill="#70b7ff"/><path d="M65 47q15-12 26 0m-23 6q10-8 18 0" fill="none" stroke="#82ddff" stroke-width="3"/>',
		'<circle cx="45" cy="38" r="20" fill="url(#green)"/><circle cx="20" cy="61" r="7" fill="#d8b974"/><circle cx="66" cy="64" r="7" fill="#d8b974"/><circle cx="80" cy="48" r="7" fill="#d8b974"/><path d="M44 16v-8h10" fill="none" stroke="#efdd9d" stroke-width="4"/>',
		'<path d="M18 16q-7 43 50 41l13-12q-48 5-49-28Z" fill="url(#gold)"/><path d="M18 16l14 1m36 40l13-12" stroke="#64411f" stroke-width="6"/>',
		'<path d="M7 37l34-5 8-22 10 1 1 20 28 8-1 8-28-3-8 22-10-1 1-22-34 2Z" fill="url(#metal)"/><path d="M45 34l8 5" stroke="#fff0b0" stroke-width="4"/>',
		'<path d="M7 37l34-5 8-22 10 1 1 20 28 8-1 8-28-3-8 22-10-1 1-22-34 2Z" fill="url(#gold)"/><circle cx="16" cy="64" r="5" fill="#ec7655"/><circle cx="75" cy="65" r="5" fill="#ec7655"/>',
		'<rect x="23" y="22" width="14" height="43" rx="6" fill="#ca4c40"/><rect x="38" y="16" width="14" height="48" rx="6" fill="#e66a4a"/><rect x="53" y="22" width="14" height="43" rx="6" fill="#ca4c40"/><path d="M20 42h50m-25-26q2-11 18-7" fill="none" stroke="#e7cb87" stroke-width="5"/>',
		'<path d="M14 50l14-13 14 7 20-23q10-7 13 4L57 52l-22 8Z" fill="#f0b191"/><path d="M77 20l12-2m-9 12l11 3" stroke="#9ee8cd" stroke-width="4"/>',
		'<path d="M18 65L59 17q16-16 25-3t-6 24L28 73Z" fill="url(#gold)"/><path d="M19 61l10 9" stroke="#5b3e2e" stroke-width="6"/>',
		'<path d="M18 57q-8-23 8-32l8 9 3-17q10-8 11 6l3-10q12-6 12 12l5-5q15 2 8 18L63 61Z" fill="#ee8465"/><path d="M26 23q-1-13 12-19l-2 17m32 2q14-15 8-22" fill="#ffc459"/>',
		'<ellipse cx="47" cy="40" rx="30" ry="17" fill="none" stroke="#a7bfff" stroke-width="8"/><ellipse cx="47" cy="40" rx="30" ry="17" fill="none" stroke="#f1e6ff" stroke-width="2"/><path d="M32 48l8-18 12 18m-6 4l8-18 12 18" fill="none" stroke="#85ebdb" stroke-width="4"/>'
	]
	var shape: String = shapes[clampi(slot-24,0,shapes.size()-1)]
	var svg := '<svg xmlns="http://www.w3.org/2000/svg" width="96" height="80" viewBox="0 0 96 80"><defs><linearGradient id="gold" x2=".6" y2="1"><stop stop-color="#ffe4a2"/><stop offset="1" stop-color="#b9762a"/></linearGradient><linearGradient id="metal" x2=".5" y2="1"><stop stop-color="#d9eee9"/><stop offset="1" stop-color="#387783"/></linearGradient><linearGradient id="green" x2=".5" y2="1"><stop stop-color="#b4cb67"/><stop offset="1" stop-color="#4a6d31"/></linearGradient></defs><g stroke="#142330" stroke-width="2.5" stroke-linejoin="round">%s</g></svg>' % shape
	var image := Image.new()
	image.load_svg_from_string(svg,3.0)
	return ImageTexture.create_from_image(image)
