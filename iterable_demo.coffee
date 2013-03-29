$(document).ready ->
    [updateQueue, resetQueue] = do ->
        abs_width  = 490
        abs_height = 180
        debugging = false

        max = (x, y) -> if x > y then x else y
        min = (x, y) -> if x < y then x else y
        confine = (n, infimum, supremum) ->
            min (max n, infimum), supremum

        colors = d3.scale.category20()

        duration = 1000
        standard_delay = duration / 5

        updateData = (parcel) ->
            # Should modify selection (svg) width and height here
            w = 40
            font_factor = 2 / 3

            # Add new objects (array elements) to be referenced elsewhere
            catalogue = []

            for pkg in parcel
                catalogue = catalogue.concat pkg['obj']

            elems = d3.select('#assets defs')
                .selectAll('.elem')
                # Need to ensure the following line isn't
                # making tons of duplicate entries
                .data(catalogue, (d) -> d)
                .enter()
                .append('svg')
                .attr('id', (d) -> "iterable_elem_#{d}")
                .classed('elem', true)
                .attr('x', 0)
                .attr('y', 0)
                .attr('width', w)
                .attr('height', w)

            elems.append('rect')
                .attr('x', 0)
                .attr('y', 0)
                .attr('width', '100%')
                .attr('height', '100%')
                .attr('fill', (d) -> colors d)

            elems.append('text')
                .attr('x', '50%')
                .attr('y', '75%')
                .attr('text-anchor', 'middle')
                .attr('fill', 'white')
                .attr('font-size', w * font_factor)
                .attr('font-family', 'sans-serif')
                .attr('font-style', 'bold')
                .text((d) -> d)

            # Update actual charts
            d3.select('#iterable_demo')
                .classed('one-child', -> parcel.length == 1)
                .classed('not-one-child', -> parcel.length != 1)
                .selectAll('.chart')
                .data(parcel, (d) -> d['name'])
                .call(charts)
                .select('.methods')
                .selectAll('.method')
                .data((d) -> d['methods'])
                .call(methods)

        charts = (selection) ->
            enteror = selection
                .enter()
                .append('div')
                .classed('chart', true)

            enteror.append('h1').append('span').append('div').text((d) -> d['name'])

            selection.exit().remove()

            enteror
                .append('div')
                .classed('demo_wrapper', true)
                .append('svg')
                .classed('demo_object', true)

            enteror
                .append('section')
                .classed('methods', true)

            selection
                .select('.demo_object')
                .each demo_object

        demo_object = (datar) ->
            selection = d3.select @
            datar = datar['obj']

            # Should modify selection (svg) width and height here
            # w = abs_width / datar.length
            # w = abs_width / 15
            w = 40
            font_factor = 2 / 3

            main_transition = selection
                .transition()
                .duration(duration / 2)
                .delay(standard_delay)
                .attr('height', w)

            x = d3.scale
                .ordinal()
                .domain(datar)
                .rangeBands([0, min abs_width, w * datar.length])

            joiner = selection
                .selectAll('svg.mover')
                .data(datar, (d) -> d)

            joiner
                .enter()
                .append('svg')
                .classed('mover', true)
                .each((d) ->
                    d3.select(@).classed("iterable_elem_#{d}", true))
                .attr('x', 0)
                .attr('y', 0)
                .attr('width', w)
                .attr('height', w)
                .append('use')
                .attr('xlink:href', (d) -> "#iterable_elem_#{d}")

            joiner.order()

            group_transition = main_transition
                .selectAll('svg.mover')
                .transition()
                .attr('x',  (d) -> x d)
                .attr('y', 0)

            joiner.exit()
                .transition()
                .duration(duration / 5)
                .delay(standard_delay)
                .ease('quad-in')
                .attr('y', 750)
                .remove()

        methods = (selection) ->
            # Suuuuper messy right now!
            # Ho no!
            # So bad, sad, et al.
            yield_width = '40px'

            selection.exit()
                .transition()
                .duration(duration / 10)
                .remove()

            props = ['name', 'args', 'block', 'yield', 'result']

            meths = selection.enter()
                .append('div')
                .classed('method', true)

            meths
                .append('span')
                .classed('name', true)
                .text((d) -> ":#{d['name']}")

            meths
                .append('span')
                .classed('args', true)
                .text((d) -> d['args'])

            meths
                .append('span')
                .classed('block', true)
                .text((d) -> d['block'])

            meths
                .append('svg')
                .attr('height', yield_width)
                .attr('width', yield_width)
                .classed('yield', true)

            meths
                .append('span')
                .classed('result', true)
                .text((d) -> d['result'])

            selection
                .select("span.name")
                .text((d) -> "#{d['name']}")

            selection
                .select("span.args")
                .text((d) -> "#{d['args']}")

            selection
                .select("span.block")
                .text((d) -> "#{d['block']}")

            selection
                .select("span.result")
                .text((d) -> "#{d['result']}")

            yielder = selection.select('svg.yield')
                .selectAll('use')
                .data(((d) -> [d['yield']]), (d) -> d)

            yielder.exit().remove()

            yielder.enter()
                .append('use')
                .attr('xlink:href', (d) -> "#iterable_elem_#{d}")
                .attr('x', 0)
                .attr('y', 0)
                .each (d) ->
                    $(@)
                        .parents('.chart')
                        .find(".iterable_elem_#{d}")
                        # Is there a more elegant 'flash-
                        # this-element' method?
                        .toggle('visible')
                        .toggle('visible')

        queue = []

        resetQueue = -> queue = [ queue[0] ] if queue.length

        updateQueue = (parcel) ->
            queue.unshift parcel unless queue[0] == parcel

        setInterval((->
            updateData queue.pop() if queue.length
        ), duration * 2)

        [updateQueue, resetQueue]


    window.AppRoutes |= {}
    window.AppRoutes.update = updateQueue
    window.AppRoutes.reset =  resetQueue
